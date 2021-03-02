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


sub list_items ($l) {
    my @a;
    while (defined $l) {
        push @a, $l->[0];
        $l= $l->[1];
    }
    @a
}

sub list_length ($l) {
    my $len= 0;
    while (defined $l) {
        $len++;
        $l= $l->[1];
    }
    $len
}

sub list_drop ($l, $n) {
    while ($n > 0) {
        $n--;
        $l= $l->[1];
    }
    $l
}

sub list_reverse ($l) {
    my $r= undef;
    while (defined $l) {
        $r= [$l->[0], $r];
        $l= $l->[1];
    }
    $r
}

sub list_find_tail ($l, $pred) {
    while (1) {
        if (defined $l) {
            if ($pred->($l->[0])) {
                return $l
            } else {
                $l= $l->[1];
            }
        } else {
            return undef
        }
    }
}

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

    sub _target_maybe_cycle ($self, $target,
                             $uplist, $globalseen) {
        my $deps= $self->target_deps($target) // do {
            # warn "target $target has no deps record";
            # This happens for "static targets".
            []
        };
        for my $dep (@$deps) {
            # XX not very performant, but shouldn't ever be too deep.
            if (my $l= Chjize::TargetDependencies::list_find_tail(
                    $uplist, sub { $_[0] eq $dep })) {
                # warn "offending dep=$dep";
                return [[$dep, $uplist], $l]
            }
            $$globalseen{$dep}++;
            if (my $hasc= $self->_target_maybe_cycle(
                    $dep, [$dep, $uplist], $globalseen)) {
                return $hasc
            }
        }
        undef
    }

    sub maybe_cycle ($self) {
        my %seen;
        for my $target ($self->alltargetnames) {
            next if $seen{$target};
            if (my $hasc= $self->_target_maybe_cycle(
                    $target, [$target, undef], \%seen)) {
                return $hasc
            }
        }
        undef
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

    my $self= bless {
        target_deps=> \%targetdeps,
        targets_refcnt=> \%targets,
        alltargets_refcnt=> \%alltargets
    }, "Chjize::_::TargetDependencies";

    if (my $c = $self->maybe_cycle) {
        my ($uplist, $l)= @$c;
        my $cyclicpart= list_drop(list_reverse($uplist), list_length($l));
        my $cpstr= join " -> ", list_items($cyclicpart);
        die "found dependency cycle: $cpstr"
    }

    $self
}

1
