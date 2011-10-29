package Dancer::Template::Xslate;

BEGIN {
  $Dancer::Template::Xslate::VERSION = '0.01';
}

# ABSTRACT: Text::Xslate wrapper for Dancer

use strict;
use warnings;
use Carp;

use Text::Xslate;
use Dancer::Config 'setting';
use File::Spec;

use base 'Dancer::Template::Abstract';

{
package Dancer::Template::Abstract;
no strict qw/subs/;
*template = sub {
    my ($class, $view, $tokens, $options) = @_;
    my ($content, $full_content);
    my $engine = Dancer::Template->engine;
    # it's important that $tokens is not undef, so that things added to it via
    # a before_template in apply_renderer survive to the apply_layout. GH#354
    $tokens  ||= {};
    $options ||= {};
    if ($view) {
        # check if the requested view exists
        $view = $engine->view($view);
        my $view_path = path(Dancer::App->current->setting('views'), $view);
        if (-e $view_path) {
            $content = $engine->apply_renderer($view, $tokens);
        } else {
            Dancer::Logger::error("Supplied view ($view) was not found.");
            return Dancer::Error->new(
                          code => 500,
                          message => 'view not found',
                   )->render();
        }
    } else {
        $content = delete $options->{content};
    }
    defined $content and $full_content =
      $engine->apply_layout($content, $tokens, $options);
    defined $full_content
      and return $full_content;
    Dancer::Error->new(
        code    => 404,
        message => "Page not found",
    )->render();
};
}

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

sub view {
    my ($self, $view) = @_;
    $view = $self->_template_name($view);
    return $view;
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;
    my $layout_name = $self->_template_name($layout);
    my $layout_path = File::Spec->catfile('layouts', $layout_name);
    my $full_content =
      Dancer::Template->engine->render($layout_path,
        {%$tokens, content => $content});
    $full_content;
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

