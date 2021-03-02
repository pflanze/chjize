#
# Copyright 2021 by Christian Jaeger <ch@christianjaeger.ch>
#

=head1 NAME

Chjize::TargetDependencies

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chjize::TargetDependencies;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';
use Exporter "import";

our @EXPORT=qw(targetDependencies);
our @EXPORT_OK=qw();
our %EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

package Chjize::_::TargetDependencies {
    my $accessor1= sub ($field) {
        sub ($self, $key) {
            $self->{$field}{$key}
        }
    };
    *target_deps= $accessor1->("target_deps");
    *targets_refcnt= $accessor1->("targets_refcnt");
    *alltargets_refcnt= $accessor1->("alltargets_refcnt");

    # Sorted
    sub alltargetnames ($self) {
        sort keys %{$self->{alltargets_refcnt}}
    }

    # Only the ones given
    sub targetnames ($self) {
        sort keys %{$self->{target_deps}}
    }
}

sub targetDependencies ($makefile_path, $targetsfh) {
    my $makefile= do {
        local $/;
        open my $in, "<", $makefile_path or die $!;
        <$in>
    };

    my %targetdeps; # target => [deps]
    my %targets;    # targets from stdin => refcount
    my %alltargets; # targets from stdin plus dependencies that might not
                    # be listed in the former => refcount

    for my $target (<STDIN>) {
        chomp $target;
        $targets{$target}++;
        $alltargets{$target}++;
        my @m= grep {
            # handle the same change as commit
            # 97090e0279b70cffe0eb04a31811d2501bd3c49a did to
            # sbin/make-targets
            not /^:?=/
        } $makefile=~ m/\n$target:([^\n]*)/g;
        @m or die "can't find target '$target' in makefile '$makefile_path'";
        for my $deps (@m) {
            $deps=~ s/#.*//; # remove comments
            my @deps= split /\s+/, $deps;
            push @{$targetdeps{$target}},
                map {
                    $alltargets{$_}++;
                    $_
                    } grep {length $_} @deps;
        }
    }

    bless {
        target_deps=> \%targetdeps,
        targets_refcnt=> \%targets,
        alltargets_refcnt=> \%alltargets
    }, "Chjize::_::TargetDependencies"
}

1
