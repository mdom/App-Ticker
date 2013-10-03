use strict;
use warnings;
use Test::More;
use App::Ticker::Item;
use App::Ticker::Filter::FullContent;
use Mojolicious::Lite;
use FindBin qw($Bin);

my $static = app->static;
push @{$static->paths}, "$Bin/html";
app->log->level('fatal');

use Mojo::UserAgent;
my $ua = Mojo::UserAgent->new( app => app);


my $filter = App::Ticker::Filter::FullContent->new({
	rules => {
		'.' => {
			body => [ '#body' ]
		}
	},
	ua => $ua,
});

my $item = App::Ticker::Item->new(
	link => "/full_content1.html",
	description => 'unchanged',
);

use EV;
use AnyEvent;
my $cv = AnyEvent->condvar;

my $cb = sub {
	my $item = shift;
	is($item->body,'<p id="body">changed</p>','fetched single page body');
	$cv->send;
};

$filter->process_item($item,$cb);

$cv->recv;

done_testing;
