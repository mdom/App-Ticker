use strict;
use warnings;
use Test::More;
use App::Ticker::Item;
use App::Ticker::Filter::FullContent;
use Mojolicious::Lite;
use FindBin qw($Bin);
use AnyEvent;
use Mojo::UserAgent;

my $static = app->static;
push @{ $static->paths }, "$Bin/html";
app->log->level('fatal');

check_fullcontent(
    {
        body => ['#body'],
    },
    '/full_content1.html',
    '<p id="body">changed</p>',
    'fetched page body at item link',
);

check_fullcontent(
    {
        body => ['#notthere'],
    },
    '/full_content1.html',
    'unchanged',
    'do not change body if link is not found',
);

check_fullcontent(
    {
        single_page_link => ['a#single_page'],
        body             => ['#body'],
    },
    '/full_content2.html',
    '<p id="body">single page body</p>',
    'fetched single page of multipage text'
);

check_fullcontent(
    {
        next_page_link => ['a#next'],
        body           => ['#body'],
    },
    '/full_content4.html',
    '<p id="body">page 1</p><p id="body">page 2</p><p id="body">page 3</p>',
    'fetched multiple pages of text'
);



sub check_fullcontent {
    my ( $rules, $url, $result, $desc ) = @_;
    my $ua = Mojo::UserAgent->new( app => app );
    my $filter = App::Ticker::Filter::FullContent->new(
        {
            rules => { '.' => $rules, },
            ua    => $ua,
        }
    );

    my $item = App::Ticker::Item->new(
        link        => $url,
        description => 'unchanged',
    );

    my $cv = AnyEvent->condvar;

    my $cb = sub {
        my $item = shift;
        is( $item->body, $result, $desc );
        $cv->send;
    };

    $filter->process_item( $item, $cb );

    $cv->recv;
}

done_testing;
