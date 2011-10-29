package Dancer::Template::Xslate;

BEGIN {
  $Dancer::Template::Xslate::VERSION = '0.02';
}

# ABSTRACT: Text::Xslate wrapper for Dancer

use strict;
use warnings;
use Carp;

use Text::Xslate;
use Dancer::Config 'setting';
use File::Spec;

use base 'Dancer::Template::Abstract';

sub default_tmpl_ext { "tx" }

sub init {
    my $self = shift;

    my %args = (
        %{$self->config},
    );
    my $views = setting('views') || '.';
    my $path = [ $views ];

    my $_engine = Text::Xslate->new(%args, path => $path, );
    $self->{_engine} = $_engine;
}

sub _template_name {
    my ( $self, $view ) = @_;
    my $def_tmpl_ext = $self->config->{suffix} || $self->default_tmpl_ext();
    $def_tmpl_ext =~ s/^\.//;
    $view .= ".$def_tmpl_ext" if $view !~ /\.\Q$def_tmpl_ext\E$/;
    return $view;
}

sub render {
    my ($self, $template, $tokens) = @_;
    my $_engine = $self->{_engine};
    my $path = $_engine->{path};
    my $views = File::Spec->rel2abs( setting('views') || '.' );
    unless ( grep {$_ eq $views} @$path ) {
        my $error = qq/Couldn't change include_path to "$views"/;
        croak $error;
    }

    $template =~ s/^\Q$views\E//;
    my $content = eval {
        $_engine->render($template, $tokens)
    };

    if (my $err = $@) {
        my $error = qq/Couldn't render template "$err"/;
        croak $error;
    }

    return $content;
}

1;

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Text::Xslate> module.

In order to use this engine, use the template setting:

    template: xslate

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

You can configure L<Text::Xslate> :

    template: xslate
    engines:
      xslate:
        syntax: TTerse
        suffix: ".tt"
        module:
          - Text::Xslate::Bridge::TT2 # to keep partial compatibility
        cache: 1
        cache_dir: "xslate_cache"

=head1 SEE ALSO

L<Dancer>, L<Text::Xslate>, L<http://xslate.org/>

