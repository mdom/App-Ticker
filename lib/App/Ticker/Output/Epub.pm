package App::Ticker::Output::Epub;
use Moo;
extends 'App::Ticker::Plugin';

use EBook::EPUB;
use Template::Tiny;
use Mojo::ByteStream 'b';
use Path::Tiny;

has 'output_dir' => ( is => 'rw', default => 'epub' );

sub run {
	my ($self) = @_;
	my @items = sort { $a->pubDate cmp $b->pubDate } @{$self->items};
	for my $item ( @items ) {
		$item->body(Mojo::DOM->new($item->body)->to_xml);
	}
	my @chapters;
	while (@items) {
		my $size = @items >= 10 ? 10 : @items;
		push @chapters, [splice(@items,0,$size)];
	}

	my $epub = EBook::EPUB->new();
	$epub->add_title('Ticker');
	my $template = do { local($/); <DATA> };
	my $tt = Template::Tiny->new( TRIM => 1 );
	
        my $num = 1;
	for my $chapter ( @chapters ) {
		my $xhtml;
		$tt->process( \$template, {
			items => $chapter,
		}, \$xhtml);
		$epub->add_xhtml("chapter_$num.xhtml",$xhtml);
		$num++;
	}
	my $dir = path($self->output_dir);
	my $file = $dir->child("ticker.epub");
	$dir->mkpath;
	$epub->pack_zip("$file");
	return;
}

1;

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Chapter</title>
  </head>
  <body>
  [% FOREACH item IN items %]
  <h2>[% item.title %]</h2>
  [% item.body %]
  [% END %]
	
  </body>
</html>
