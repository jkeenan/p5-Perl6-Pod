#===============================================================================
#
#  DESCRIPTION:  test U<> implementation
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package T::FormattingCode::U;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::To::XHTML;
use XML::ExtOn('create_pipe');
use base 'TBase';

sub t01_as_xml : Test {
    my $t = shift;
    my $x = $t->parse_to_xml( <<T);
=para
Bold U<test>
T
    $t->is_deeply_xml(
        $x,
q#<para pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'>Bold <U pod:type='code'>test</U>
</para>#
    );
}

sub t02_as_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
Unusual U<test>
T
    $t->is_deeply_xml(
        $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p >Unusual <em class="unusual">test</em>
 </p></xhtml>#
    );
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=para
Bold U<test>
T

 $t->is_deeply_xml(
        $x,
q#<chapter><para>Bold <emphasis role='underline'>test</emphasis>
</para></chapter>#)
}

1;

