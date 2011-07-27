use strict;
use warnings;
use Test::More import => ["!pass"];

use Dancer ':syntax';
use Dancer::Test;

plan tests => 2;

setting views   => 't';
setting template => 'xslate';

# change views need recreate Text::Xslate instance
setting views   => 't/views';
setting template => 'xslate';

ok(
    get '/' => sub {
        template 'index', { loop => [1..2] };
    }
);

response_content_like( [ GET => '/' ], qr/1<br \/>\n4/ );
