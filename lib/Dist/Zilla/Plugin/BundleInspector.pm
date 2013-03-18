# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Plugin-BundleInspector
#
# This software is copyright (c) 2013 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Plugin::BundleInspector;
{
  $Dist::Zilla::Plugin::BundleInspector::VERSION = '0.001';
}
# git description: 3debba6

BEGIN {
  $Dist::Zilla::Plugin::BundleInspector::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Gather prereq and config info from PluginBundles

use Moose;
use MooseX::AttributeShortcuts;
use Dist::Zilla::Config::BundleInspector;

with qw(
  Dist::Zilla::Role::FileMunger
  Dist::Zilla::Role::PrereqSource
);

sub mvp_multivalue_args { qw( bundle ) }

has file_name_re => (
  is         => 'ro',
  isa        => 'RegexpRef',
  default    => sub {
    qr{(?: ^lib/ )? ( (?: [^/]+/ )+ PluginBundle/.+? ) \.pm$}x
  },
);

# coerce
around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);

  foreach my $re ( qw(
    file_name_re
  ) ){
    # upgrade Str to RegExp
    $args->{ $re } = qr/$args->{ $re }/
      if exists $args->{ $re };
  }

  return $args;
};


has bundles => (
  is         => 'lazy',
  isa        => 'ArrayRef',
  init_arg   => 'bundle',
);

sub _build_bundles {
  my ($self) = @_;

  # TODO: warn if ./lib/ not found in @INC?

  my $found = [
    # combine map/grep into one... it feels weird, but why do the m// more than once?
    map  { $_->name =~ $self->file_name_re ? $1 : () }
      @{ $self->zilla->files }
  ];

  s{/}{::}g for @$found;

  return $found;
}

has inspectors => (
  is         => 'lazy',
  isa        => 'HashRef',
  init_arg   => undef,
);

sub _build_inspectors {
  my ($self) = @_;
  return {
    map {
      ($_ => Dist::Zilla::Config::BundleInspector->new({ bundle_class => $_ }))
    }
      @{ $self->bundles }
  };
}

sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    %{ $_->prereqs->as_string_hash }
  )
    for values %{ $self->inspectors };
}

sub munge_file {
  my ($self, $file) = @_;

  return
    # FIXME: build up a list? join('|', map { s{::}{/}g; $_ } @{ $self->bundles })?
    unless my $class = ($file->name =~ $self->file_name_re)[0];

  $class =~ s{/}{::}g;

  return
    unless my $inspector = $self->inspectors->{ $class };

  my $content = $file->content;
  my $ini_string = $inspector->ini_string;
  chomp $ini_string;

  # prepend spaces to make verbatim paragraph
  $ini_string =~ s/^(.+)$/  $1/mg;

  $content =~ s/^=bundle_ini_string$/$ini_string/m;
  $file->content($content);

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS INI PluginBundles cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::BundleInspector - Gather prereq and config info from PluginBundles

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  ; in dist.ini
  [Bootstrap::lib]
  [BundleInspector]

=head1 DESCRIPTION

This plugin is useful when using L<Dist::Zilla> to release
a plugin bundle for L<Dist::Zilla> or L<Pod::Weaver>
(others could be supported in the future).

Each bundle inspected will be loaded to gather the plugin specs.
B<Note> that this means you will probably want to use
L<Dist::Zilla::Plugin::Bootstrap::lib>
in order to inspect the included bundle
(rather than an older, installed version).

This plugin does L<Dist::Zilla::Role::PrereqSource>
and the bundle's plugin specs will be used
to determine additional prereqs for the dist.

Additionally this plugin does L<Dist::Zilla::Role::FileMunger>
so that if you include a line in the pod of your plugin bundle
of exactly C<=bundle_ini_string> it will be replaced with
a verbatim block of the roughly equivalent INI config for the bundle.

=head1 ATTRIBUTES

=head2 bundle

Specify the name of a bundle to inspect.
Can be used multiple times.

If none are specified the plugin will attempt to discover
any included bundles.

=for Pod::Coverage munge_file
mvp_multivalue_args
register_prereqs

=head1 SEE ALSO

=over 4

=item *

L<Config::MVP::Writer::INI>

=item *

L<Config::MVP::BundleInspector>

=item *

L<Dist::Zilla::Config::BundleInspector>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::BundleInspector

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-BundleInspector>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-BundleInspector>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-BundleInspector>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-BundleInspector>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-BundleInspector>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::BundleInspector>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-bundleinspector at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-BundleInspector>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Dist-Zilla-Plugin-BundleInspector>

  git clone https://github.com/rwstauner/Dist-Zilla-Plugin-BundleInspector.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
