package App::Ticker::Filter::FullContent;
use Moo;
extends 'App::Ticker::Filter';
with 'App::Ticker::Role::DomainRule', 'App::Ticker::Role::FetchURL';

use Mojo::URL;
use Mojo::DOM;
use Try::Tiny;
use HTML::ExtractMain qw( extract_main_html );

sub process_item {
    my ( $self, $item, $cb ) = @_;
    my $rule = $self->get_rule($item);
    if ( $rule and ( exists $rule->{body} or exists $rule->{auto} )) {
        my $url = $item->link;
        $self->ua->get(
            $url,
            sub {
                my ( $ua, $tx ) = @_;
                if ( my $res = $tx->success ) {
                    my $dom = $res->dom;
                    my $html;
                    my $cb = sub { 
                        my $item = shift;
                        $self->resolve_link( $item, $tx->req->url );
                        $cb->($item);
                    };
                    if ( exists $rule->{single_page_link} ) {
                        $self->get_single_page( $dom, $rule, $item, $cb );
                    }
                    elsif ( exists $rule->{next_page_link} ) {
			if ( my $body = $self->get_body( $dom, $rule ) ) {
			    $item->body( $body );
                            $self->get_multi_page( $dom, $rule, $item, $cb );
			}
			else {
			    $cb->($item);
			}
                    }
                    else {
			if ( my $body = $self->get_body( $dom, $rule ) ) {
                            $item->body($body);
			}
                        $cb->($item);

                    }
                }
		else {
		    $cb->($item);
                }
		
       });
    } else {
        $cb->($item);
    }
    return;
}

sub get_multi_page {
    my ( $self, $dom, $rule, $item, $cb ) = @_;
    if ( my $url = $self->get_multi_page_link( $dom, $rule ) ) {
        $self->ua->get(
            $url,
            sub {
                my ( $ua, $tx ) = @_;
                if ( my $res = $tx->success ) {
                    $dom = $res->dom;
                    if ( my $body = $self->get_body( $dom, $rule ) ) {
			    $item->body( $item->body . $body );
			    $self->get_multi_page( $dom, $rule, $item, $cb );
	            }
		    else {
		        $cb->($item);
		    }
                }
		else {
		    $cb->($item);
		}
            }
        );
    }
    else {
        $cb->($item);
    }
    return;
}

sub get_multi_page_link {
    my ( $self, $dom, $rule ) = @_;
    my $url;
    for my $selector ( @{ $rule->{next_page_link} } ) {
        my $link = $dom->at($selector);
        next if !$link;
        $url = $link->attr('href');
        last if $url;
    }
    return $url;
}

sub get_single_page {
    my ( $self, $dom, $rule, $item, $cb ) = @_;
    my $url;
    for my $selector ( @{ $rule->{single_page_link} } ) {
        my $link = $dom->at($selector);
        $url = $link->attr('href');
        last if $url;
    }
    if ($url) {
        $self->ua->get(
            $url,
            sub {
                my ( $ua, $tx ) = @_;
                if ( my $res = $tx->success ) {
                    my $dom = $res->dom;
                    if ( my $body = $self->get_body( $dom, $rule ) ) {
                        $item->body($body);
	            }
                }
                $cb->($item);
                return;
            }
        );
    }
    else {
        $cb->($item);
    }
    return;
}

sub get_body {
    my ( $self, $dom, $rule ) = @_;
    if ( $rule->{auto} ) {
        return try { extract_main_html( $dom->to_string, output_type => 'html' ) };
    }
    elsif ( @{ $rule->{body} } ) {
        my $collection;
        for my $body ( @{ $rule->{body} } ) {
            $collection = $dom->find($body);
            last if $collection->size;
        }
        if ( $collection and $collection->size ) {
            $dom = Mojo::DOM->new( $collection->join('')->to_string );
            return $dom->to_string;
        }
    }
    return;
}

sub resolve_link {
    my ( $self, $item, $base ) = @_;
    $base = Mojo::URL->new($base);
    my $dom   = Mojo::DOM->new($item->body);
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
    $item->body($dom->to_string);
    return;
}

1;
