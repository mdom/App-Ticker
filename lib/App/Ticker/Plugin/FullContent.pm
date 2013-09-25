package App::Ticker::Plugin::FullContent;
use Moo;
extends 'App::Ticker::Plugin';
with 'App::Ticker::Role::FetchURL';

use Mojo::ByteStream 'b';
use List::MoreUtils qw(uniq);

has 'feeds' => (
	is => 'rw',
	required => 1,
);

sub process_item {
    my ( $self, $item ) = @_;
    my $selector = $self->feeds->{$item->feed->link}->{full_content_selector};
    if ($selector) {
        $self->get_content( $item, $selector );
    }
    return;
};

sub get_all_links {
    my ( $response, $selector ) = @_;

    my $tree =
      HTML::TreeBuilder::XPath->new->parse( $response->decoded_content() )->eof;
    my $xpath = HTML::Selector::XPath->new($selector)->to_xpath;
    my @urls;
    for my $elem ( $tree->findnodes($xpath) ) {
        my $rel_url  = $elem->attr_get_i('href');
        my $base_url = $response->base;
        push @urls, URI->new_abs( $rel_url, $base_url );
    }
    return uniq @urls;
}

sub unpaginate {
    my ( $ua, $url, $page_selector, $content_selector ) = @_;

    my @responses;
    push @responses, _get( $ua, $url );
    my @urls = get_all_links( $responses[0], $page_selector );
    for my $url (@urls) {
        push @responses, _get( $ua, $url );
    }
    my $content = '';
    for my $response (@responses) {
        $content .= filter_content( $response, $content_selector );
    }
    return $content;
}

sub get_content {
    my ( $self, $item, $selector ) = @_;
    my $tx = $self->get_url( $item->link );
    if ( my $res = $tx->success ) {
        my $html = $res->dom($selector)->join('')->to_string;
        $html = $self->resolve_link( $html, $tx->req->url );
        $item->body($html);
    }
    return;
}

sub resolve_link {
    my ( $self, $html, $base ) = @_;
    $base = Mojo::URL->new($base);
    my $dom   = Mojo::DOM->new($html);
    my %types = (
        a   => 'href',
        img => 'src',
    );
    for my $element ( $dom->find( join( ',', keys %types ) )->each ) {
        my $attr = $types{ $element->type };
        my $url  = Mojo::URL->new( $element->attr($attr) );
        next if $url->is_abs;
        $element->attr( $attr => $url->base($base)->to_abs );
    }
    return $dom->to_xml;
}

1;
