package Dancer::Template::Xslate;

BEGIN {
  $Dancer::Template::Xslate::VERSION = '0.01';
}

# ABSTRACT: Text::Xslate wrapper for Dancer

use strict;
use warnings;

use Text::Xslate;
use Dancer::Config 'setting';
use Dancer::FileUtils 'path';

use base 'Dancer::Template::Abstract';

my $_engine;

sub default_tmpl_ext { "tx" }

sub init {
    my $self = shift;

    my %args = (
        %{$self->config},
    );
    my $views = setting('views') || '.';
    my $path = [ $views ];

    $_engine = Text::Xslate->new(%args, path => $path, );
}

sub _template_name {
    my ( $self, $view ) = @_;
    my $def_tmpl_ext = $self->config->{suffix} || $self->default_tmpl_ext();
    $def_tmpl_ext =~ s/^\.//;
    $view .= ".$def_tmpl_ext" if $view !~ /\.\Q$def_tmpl_ext\E$/;
    return $view;
}

sub view {
    my ($self, $view) = @_;
    $view = $self->_template_name($view);
    return $view;
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;
    my $layout_name = $self->_template_name($layout);
    my $layout_path = path('layouts', $layout_name);
    my $full_content =
      Dancer::Template->engine->render($layout_path,
        {%$tokens, content => $content});
    $full_content;
}


sub render {
    my ($self, $template, $tokens) = @_;

    my $content = eval {
        $_engine->render($template, $tokens)
    };

    if (my $err = $@) {
        my $error = qq/Couldn't render template "$err"/;
        die $error;
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

