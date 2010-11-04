package Perl6::Pod::FormattingCode::C;

#$Id$

=pod

=head1 NAME

Perl6::Pod::FormattingCode::C - Contained text is code

=head1 SYNOPSIS

        =para
        Use C<=config> for this or C<< $i > 4 >>;

=head1 DESCRIPTION

The C<CE<lt>E<gt>> formatting code specifies that the contained text is code; that is, something that might appear in a program or specification. Such content would typically be rendered in a fixed-width font (preferably a different font from that used for the C<TE<lt>E<gt>> or C<KE<lt>E<gt>>  formatting codes) or with  <samp>...</samp>  tags. The contents of a C<CE<lt>E<gt>> code are space-preserved  and verbatim. The C<CE<lt>E<gt>> code is the inline equivalent of the =code  block. 

To include other formatting codes in a C<CE<lt>E<gt>> code, you can lexically reconfigure  it:

    =begin para
    =config C<> :allow<E I>
    Perl 6 makes extensive use of the C<E<laquo>> and C<E<raquo>>
    characters, for example, in a hash look-up:
    C<%hashI<E<laquo>>keyI<E<raquo>>>
    =end para

To enable entities in every C<CE<lt>...E<gt>> put a =config C<CE<lt>E<gt>>> :allowC<CE<lt>EE<gt>> at the top of the document 

Exported :

=over 

=item *  docbook 

    <code></code>

L<http://www.w3.org/TR/html401/struct/text.html#edef-CODE>

=item * html 

  <code></code>

L<http://www.w3.org/TR/html401/struct/text.html#edef-CODE>

=back

=cut
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
use strict;
use warnings;

sub on_para {
    my ($self, $p ,$t )= @_;
    #no process format codes
    return $t;
}

sub _html_escape {
    my ( $txt ) =@_;
    $txt   =~ s/&/&amp;/g;
    $txt   =~ s/</&lt;/g;
    $txt   =~ s/>/&gt;/g;
#    $txt   =~ s/"/&quot;/g;
#    $txt   =~ s/'/&apos;/g;
    $txt
}

sub to_xhtml {
    my $self   = shift;
    my $parser = shift;
    my $el =
      $parser->mk_element('code')->add_content( $parser->_make_elements(@_) );
    return $el;
}

sub to_docbook {
    my $self   = shift;
    return $self->to_xhtml(@_)
}

1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut



