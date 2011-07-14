use strict;
use warnings;

use Guard;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use File::Temp qw/ :mktemp  /;
use POSIX::RT::SharedMem qw(shared_unlink);

use Plack::Middleware::AccessCount;
my $path = mktemp('/access_counterXXXXXX');

my $m = Plack::Middleware::AccessCount->new({
	counter_path => $path
});

$m->wrap(sub {
	my $env = shift;

	[200, [ 'Content-Type' => 'text/plain' ], [ $env->{'psgix.access_counter'} . '' ]  ]
});

test_psgi $m => sub { my $server = shift;
	is $server->(GET '/')->content, "1";
	is $server->(GET '/')->content, "2";
	is $server->(GET '/')->content, "3";
	
	{
		my $pid;
		unless ($pid = fork) {
			is $server->(GET '/')->content, "4";
			exit;
		}
		wait;
	};

	is $server->(GET '/')->content, "5";

	{
		my $pid;
		unless ($pid = fork) {
			is $server->(GET '/')->content, "6";
			exit;
		}
		wait;
	}

	is $server->(GET '/')->content, "7";
};

shared_unlink $path;
done_testing;
