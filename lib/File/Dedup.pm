package File::Dedup;

use strict;
use warnings;

use feature qw(say);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

sub new {
   my ($class, %opts) = @_;

   die "Must pass a directory to process"
      unless exists $opts{directory};
   die "Supplied directory argument '$opts{directory}' is not a directory"
      unless -d $opts{directory};
   
   # default to always asking before purging
   $opts{ask} ||= 1;
   
   # default to non-recursive
   $opts{recursive} = 0 
      unless exists $opts{recursive} && defined $opts{recursive};
   
   return bless \%opts, $class;
}

sub directory {
   return shift->{directory};
}

sub purge {
   return shift->{purge};
}

sub recursive {
   return shift->{recursive};
}

sub ask {
   return shift->{ask};
}

sub _file_md5 {
   my ($filename) = @_;

   open my $fh, '<', $filename
      or die "$!";
   
   my $checksum = Digest::MD5->new->addfile($fh)->hexdigest;
   close($fh);

   return $checksum;
}

sub dedup {
   my ($self) = @_;
   my @results = $self->_dirwalk(
      $self->directory, 
      sub { [ $_[0], _file_md5 $_[0] ] }, 
      sub { shift; @_ } 
   );

   my %files_by_md5sum;
   foreach my $result ( @results ) {
      push @{ $files_by_md5sum{$result->[1]} }, $result->[0];
   }

   my %duplicates_by_md5sum =
      map  { $_ => $files_by_md5sum{$_} }
      grep { @{ $files_by_md5sum{$_} } > 1 } keys %files_by_md5sum;
   print Dumper \%duplicates_by_md5sum;
   $self->_handle_duplicates(\%duplicates_by_md5sum);
}

sub _handle_duplicates {
   my ($self, $duplicates) = @_;

   while ( my ($md5, $files) = each %$duplicates ) {
      
   }
}

sub _dirwalk {
   my ($self, $top, $filefunc, $dirfunc) = @_;

   if ( -d $top ) {
      # stop processing non-recursive searches when a directory that
      # was not the starting directory is encountered
      return 
         if $top ne $self->directory && !$self->recursive;
      
      my $DIR;
      unless ( opendir $DIR, $top ) {
         warn "Couldn't open directory '$top': $!; skipping.\n";
         return;
      }

      my @results;
      while ( my $file = readdir $DIR ) {
         next if $file =~ m/^\./; # ignore hidden files, '.', and '..'
         
         push @results, $self->_dirwalk("$top/$file", $filefunc, $dirfunc);
      }
      return $dirfunc ? $dirfunc->($top, @results) : ();
   }
   
   return $filefunc ? $filefunc->($top) : ();
}

1;

__END__

=pod 

=head1 NAME 

File::Dedup

=head1 DESCRIPTION

A small utility to identify duplicate files in a given directory and optionally delete them

=head1 SYNOPSIS

 use File::Dedup qw(dedup);
 dedup('/home/hunter/'); # uses default options

 or 

 use File::Dedup;
 File::Dedup->new( directory => '/home/hunter/', purge => 1 )->dedup;

 or 

 use File::Dedup
 my $deduper = File::Dedup->new( 
    directory => '/home/hunter/', 
    purge     => 1, 
 );
 $deduper->dedup;

=cut
