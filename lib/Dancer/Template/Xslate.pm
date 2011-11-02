package Dancer::Template::Xslate;

BEGIN {
  $Dancer::Template::Xslate::VERSION = '0.02';
}

# ABSTRACT: Text::Xslate wrapper for Dancer

use strict;
use warnings;
use Carp;
use Moo;
use Dancer::Moo::Types;
use Dancer::FileUtils qw'path';
use Text::Xslate;

with 'Dancer::Core::Role::Template';

has engine => (
  is  => 'rw',
  isa => sub { ObjectOf( 'Text::Xslate', @_ ) },
);

sub default_tmpl_ext {".tx"}

sub BUILD {
  my $self     = shift;
  my $charset  = $self->charset;
  my @encoding = length($charset) ? ( ENCODING => $charset ) : ();
  my %args     = ( %{ $self->config }, );
  my $views    = $self->{views} || '.';
  my $path     = [$views];
  $self->engine( Text::Xslate->new( %args, path => $path, ) );
}

sub _template_name {
  my ( $self, $view ) = @_;
  my $suffix = $self->config->{suffix} // default_tmpl_ext;
  $view .= $suffix if $view !~ /\Q$suffix\E$/;
  return $view;
}

sub render {
  my ( $self, $template, $tokens ) = @_;
  my $path  = $self->engine->{path};
  my $views = File::Spec->rel2abs( $self->{views} );
  unless ( grep { $_ eq $views } @$path ) {
    my $error = qq/Couldn't change include_path to "$views"/;
    croak $error;
  }
  $template =~ s/^\Q$views\E//;
  my $content = eval { $self->engine->render( $template, $tokens ) };
  if ( my $err = $@ ) {
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

