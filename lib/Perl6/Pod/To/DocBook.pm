package Test::FilterDocBook;
use strict;
use warnings;
use Test::More;
use XML::ExtOn('create_pipe');
use base 'XML::ExtOn';

sub on_start_element {
    my ( $self, $el ) = @_;
    if ( $el->local_name eq 'pod' ) {
        $el->delete_element;
    }
    return $el;
}

1;

package Perl6::Pod::To::DocBook;

#$Id$

=pod

=head1 NAME

Perl6::Pod::To::DocBook - DocBook formater 

=head1 SYNOPSIS

    my $p = new Perl6::Pod::To::DocBook:: 
                header => 0, doctype => 'chapter';


=head1 DESCRIPTION

Process pod to docbook

Sample:

        =begin pod
        =NAME Test chapter
        =para This is a test para
        =end pod

Run converter:

        pod6docbook test.pod > test.xml

Result xml:

        <?xml version="1.0"?>
        <chapter>
          <title>Test chapter
        </title>
          <para>This is a test para
        </para>
        </chapter>


=cut

use strict;
use warnings;
use Perl6::Pod::To::XML;
use Perl6::Pod::Parser::AddHeadLevels;
use Perl6::Pod::To::DocBook::ProcessHeads;
use Perl6::Pod::Parser::ListLevels;
use Perl6::Pod::Parser::Doformatted;
use Perl6::Pod::Parser::NestedAttr;
use XML::ExtOn('create_pipe');
use base qw/Perl6::Pod::To::XML/;
use constant POD_URI => 'http://perlcabal.org/syn/S26.html';
use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{out_put} =
      create_pipe( 'Perl6::Pod::To::DocBook::ProcessHeads', $self->{out_put} );
    return create_pipe(
        'Perl6::Pod::Parser::NestedAttr', 'Perl6::Pod::Parser::Doformatted',
        'Perl6::Pod::Parser::ListLevels', 'Perl6::Pod::Parser::AddHeadLevels',
        'Test::FilterDocBook',            $self
    );
}

sub start_document {
    my $self = shift;
    if ( my $out = $self->out_parser ) {
        $out->start_document;
        if ( $self->{header} ) {
            $out->start_dtd(
                {
                    Name => $self->{doctype} || 'chapter',
                    PublicId => '-//OASIS//DTD DocBook V4.2//EN',
                    SystemId =>
                      'http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd'
                }
            );
            $out->end_dtd;
        }
        my $root = $out->mk_element( $self->{doctype} || 'chapter' );
        $out->start_element($root);
    }
}

sub end_document {
    if ( my $out = $_[0]->out_parser ) {
        my $root = $out->mk_element( $_[0]->{doctype} || 'chapter' );
        $out->end_element($root);
        $out->end_document;
    }
}

sub _make_xml_element {
    my $self     = shift;
    my $elem     = shift;
    my $e_type   = $elem->isa('Perl6::Pod::FormattingCode') ? 'code' : 'block';
    my $out_elem = $self->out_parser->mk_element( $elem->local_name );
    my ( $out_attr, $attr ) = ( $out_elem->attrs_by_name, $elem->get_attr );
    while ( my ( $key, $val ) = each %$attr ) {
        my $xml_str = $val;
        if ( ref($val) eq 'ARRAY' ) {
            $xml_str = join "," => @$val;
        }
        $out_attr->{$key} = $xml_str;
    }
    return $out_elem;
}

sub process_element {
    my $self = shift;
    my $elem = shift;
    my $res;
    if ( $elem->can('to_docbook') ) {
        $res = $elem->to_docbook( $self, @_ );
        unless ( ref($res) ) {
            $res = $self->out_parser->mk_from_xml($res);
        }
    }
    else {
        #skip all _UPPER_CASE_SPESIAL_ tags
        my $lname = $elem->local_name();
        if (  $lname eq uc($lname) and $lname=~ /^_+.*_$/ ) {
            return [ $self->_make_elements(@_) ]
        }
        #make characters from unhandled texts
        my @out_content = ();
        for (@_) {
            push @out_content,
              ref($_) ? $_ : $self->out_parser->mk_characters($_);
        }
        $res = $self->_make_xml_element($elem)->add_content(@out_content);
    }
    return $res;
}

sub export_block {
    my $self = shift;
    return $self->process_element(@_);
}

sub export_code {
    my $self = shift;
    return $self->process_element(@_);
}

sub print_export {
    my $self = shift;
    for (@_) {
        my @data = ref($_) eq 'ARRAY' ? @{$_} : $_;
        $self->out_parser->_process_comm($_) for @data;
    }
}

sub on_para {
    my $self = shift;
    my ( $element, $text ) = @_;
    push @{ $element->{_CONTENT_} }, $text;
    return;
}

sub on_end_block {
    my $self = shift;
    my $el   = shift;
    return $el unless $el->isa('Perl6::Pod::Block');
    my $content = exists $el->{_CONTENT_} ? $el->{_CONTENT_} : undef;
    my $data = $self->__handle_export( $el, @$content );
    my $cel = $self->current_root_element;
    if ($cel) {
        push @{ $cel->{_CONTENT_} }, ref($data) eq 'ARRAY' ? @$data : $data;
        return;
    }
    else {

        $self->print_export($data);
    }
    return $el;
}

sub export_block__DEFN_TERM_ {
    my ( $self, $el, @p ) = @_;
    return $self->mk_element('term')->add_content( $self->_make_events(@p) );
}

sub export_block__ITEM_ENTRY_ {
    my ( $self, $el, @p ) = @_;
    my $attr = $el->attrs_by_name;
    my ( $list_name, $items_name ) = @{
        {
            ordered    => [ 'orderedlist',  'listitem' ],
            unordered  => [ 'itemizedlist', 'listitem' ],
            definition => [ 'variablelist', 'listitem' ]
        }->{ $attr->{listtype} }
      };
    unless ( $attr->{is_multi_para} ) {
        @p =
          ( $self->mk_element('para')->add_content( $self->_make_events(@p) ) );
    }
    my $res =
      $self->mk_element($items_name)->add_content( $self->_make_events(@p) );
    return $res;

}

sub export_block__LIST_ITEM_ {
    my ( $self, $el, @p ) = @_;
    
    #check type of list
    my $attr = $el->attrs_by_name;
    my ( $list_name, $items_name ) = @{
        {
            ordered    => [ 'orderedlist',  'listitem' ],
            unordered  => [ 'itemizedlist', 'listitem' ],
            definition => [ 'variablelist', 'listitem' ]
        }->{ $attr->{listtype} }
      };
    my $res =
      $self->mk_element($list_name)->add_content( $self->_make_events(@p) );
    #do nesting
    my $item_level = $el->attrs_by_name->{item_level} || 1;
    #add level marker
    if ( $list_name eq 'itemizedlist' and $item_level > 1) {
     #get list from http://www.sagehill.net/docbookxsl/Itemizedlists.html
     my @markers= qw/bullet opencircle box /;
     $res->attrs_by_name->{mark} = $markers[ ($item_level-1) % 3  ];
    } elsif ( $list_name eq 'orderedlist'){
            #set continuation -> continues
        if ( $attr->{number_start} != 1 ) {
            #set continuation -> continues
#            warn Dumper {$el->local_name => $attr};
           $res->attrs_by_name->{continuation} = 'continues'; 
        }
    }
    if ( my $count = $item_level -1 ) {
        for (1..$count) {
            my $nest =  $self->mk_element('blockquote');
            $res = $nest->add_content( $res);
        }
    }
    return $res;
}

sub export_block_NAME {
    my ( $self, $el, @in ) = @_;
    return $self->mk_element('title')->add_content( $self->_make_events(@in) );
}

#for N clean any extra tags
sub export_block__NOTES_ {
    return;
}

sub export_block__NOTE_ {
    return;
}

1;
__END__


=head1 SEE ALSO

L<http://perlcabal.org/syn/S26.html>

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

