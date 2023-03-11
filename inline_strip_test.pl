#!/usr/bin/perl 
  
use Benchmark qw(:all) ;

use Inline CPP => config => typemaps => './typemap'; ## cppxs will look for typemap if you use that
use Inline CPP => config => ccflags => '-Wall -c -std=c++11 -I/usr/local/include';
use Inline CPP => config => inc => '-I/usr/local/include';
use Inline CPP => config => cc => '/usr/bin/g++';
use Inline CPP => <<'END';

#include <string>
#include <cctype>
#include <iostream> 
#include <algorithm>
#include <cstring> // for access to std::strlen

#define extract_string_from_scalar_value SvPV_nolen
#define set_string_value_of_scalar_value sv_setpv 

typedef std::string cppstring;

SV * cpp_char_strip(const char* str) {
    const int length = std::strlen(str);
    char* result = new char[length+1];
    int result_index = 0;

    bool last_char_was_space = true;
    for (int i = 0; i < length; i++) {
        char c = str[i];
        if (std::isalnum(c)) {
            result[result_index++] = std::tolower(c);
            last_char_was_space = false;
        } else if (!last_char_was_space) {
            result[result_index++] = ' ';
            last_char_was_space = true;
        }
    }

    result[result_index] = '\0'; // terminate the string
    SV* outsv = newSVpv(result, result_index);
    Safefree(result);
    return outsv;
}

cppstring cpp_strip(cppstring str) {
        bool last_char_was_space = true;

        std::string result;
        result.reserve(str.size());

        for (char c : str) {
                if (isalnum(c)) {
                        result += char(tolower(c));
                        last_char_was_space = false;
                } else if (!last_char_was_space) {
                        result += ' ';
                        last_char_was_space = true;
                }
        }

        return result;
}


END

my $longstring = "[ Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.

Why do we use it?
It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).


Where does it come from?
Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of de Finibus Bonorum et Malorum (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum ... ]\n";

my $shortstring = "Hello World, Some Test!!!!";

for my $string ( $shortstring, $longstring ) {
        my $t0 = Benchmark->new;
        for( 0..100000) {
                $s = cpp_char_strip( $string );
        }
        my $t1 = Benchmark->new;
        warn "cpp char* for loop char strip took " . timestr( timediff($t1, $t0) ) . "result is \n\n$s\n\n" ;


        $t0 = Benchmark->new;
        for( 0..100000) {
                $s = cpp_strip( $string );
        }
        $t1 = Benchmark->new;
        warn "cpp for loop strip took " . timestr( timediff($t1, $t0) ) . " result is \n\n$s\n\n" ;


        $t0 = Benchmark->new;
        for( 0..100000) {
                $s = perl_strip( $string );
        }

        $t1 = Benchmark->new;
        warn "perl for loop strip took " . timestr( timediff($t1, $t0) ) . " result is \n\n$s\n\n";


        $t0 = Benchmark->new;
        for( 0..100000) {
                $s = regex_strip ( $string );
        }
        $t1 = Benchmark->new;
        warn "regex strip took " . timestr( timediff($t1, $t0) ) . " result is \n\n$s\n\n";

}

sub perl_strip {
    my ($str) = @_;

    my $result = '';
    my $last_char_was_space = 1;
    for my $c (split //, $str) {
        if ($c =~ /[a-zA-Z0-9]/) {
            $result .= lc $c;
            $last_char_was_space = 0;
        } elsif (!$last_char_was_space) {
            $result .= ' ';
            $last_char_was_space = 1;
        }
    }
    return $result;
}

sub regex_strip {
        my ( $string ) = @_;
	$string =~ s/[^0-9a-zA-Z]/ /g;
	#$string =~ s/^\w/ /g;
        $string =~ s/ +/ /g;
        $string =~ s/^ +//;
        $string =~ s/ +$//;
        lc $string;
}

