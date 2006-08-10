#!/usr/bin/perl -w

#
# This file is released under the terms of the Artistic License.
# Please see the file LICENSE, included in this package, for details.
#
# Copyright (C) 2002 Mark Wong & Open Source Development Lab, Inc.
#
# 2006 Rilson Nascimento

# TRADE_ORDER
# TRADE_RESULT
# TRADE_LOOKUP
# TRADE_UPDATE
# TRADE_STATUS
# CUSTOMER_POSITION
# BROKER_VOLUME
# SECURITY_DETAIL
# MARKET_FEED
# MARKET_WATCH
# DATA_MAINTENANCE

use strict;
use Getopt::Long;
use Statistics::Descriptive;
use POSIX qw(ceil floor);

my $mix_log;
my $help;
my $outdir;
my $verbose;

my @trade_order_response_time = ();
my @trade_result_response_time = ();
my @trade_lookup_response_time = ();
my @trade_update_response_time = ();
my @trade_status_response_time = ();
my @customer_position_response_time = ();
my @broker_volume_response_time = ();
my @security_detail_response_time = ();
my @market_feed_response_time = ();
my @market_watch_response_time = ();
my @data_maintenance_response_time = ();

my @transactions = ( "trade_order", "trade_result", "trade_lookup",
	"trade_update", "trade_status", "customer_position",
	"broker_volume", "security_detail", "market_feed",
	"market_watch", "data_maintenance" );
#
# I'm so lazy, and I really don't like perl...
#
my %transaction;
$transaction{ '0' } = "Trade Order      ";
$transaction{ '1' } = "Trade Result     ";
$transaction{ '2' } = "Trade Lookup     ";
$transaction{ '3' } = "Trade Update     ";
$transaction{ '4' } = "Trade Status     ";
$transaction{ '5' } = "Customer Position";
$transaction{ '6' } = "Broker Volume    ";
$transaction{ '7' } = "Security Detail  ";
$transaction{ '8' } = "Market Feed      ";
$transaction{ '9' } = "Market Watch     ";
$transaction{ 'D' } = "Data Maintenance ";


my @xtran = ( "to_tran", "tr_tran", "tl_tran", "tu_tran", "ts_tran",
	"cp_tran", "bv_tran", "sd_tran", "mf_tran", "mw_tran", "dm_tran" );

my $sample_length = 60; # Seconds.

GetOptions(
	"help" => \$help,
	"infile=s" => \$mix_log,
	"outdir=s" => \$outdir,
	"verbose" => \$verbose
);

#
# Because of the way the math works out, and because we want to have 0's for
# the first datapoint, this needs to start at the first $sample_length,
# which is in minutes.
#
my $elapsed_time = 1;

#
# Isn't this bit lame?
#
if ( $help ) {
	print "usage: mix_analyzer.pl --infile mix.log --outdir <path>\n";
	exit 1;
}

unless ( $mix_log ) {
	print "usage: mix_analyzer.pl --infile mix.log --outdir <path>\n";
	exit 1;
}

unless ( $outdir ) {
	print "usage: mix_analyzer.pl --infile mix.log --outdir <path>\n";
	exit 1;
}

#
# Open a file handle to mix.log.
#
open( FH, "<$mix_log")
	or die "Couldn't open $mix_log for reading: $!\n";

#
# Open a file handle to output data for gnuplot.
#
open( CSV, ">$outdir/trtps.data" )
	or die "Couldn't open $outdir/trtps.data for writing: $!\n";

#
# Load mix.log into memory.  Hope perl doesn't choke...
#
my $line;
my %data;
my %last_time;
my %error_count;
my $errors = 0;

#
# Hashes to determine response time distributions.
#
my %to_distribution;
my %tr_distribution;
my %tl_distribution;
my %tu_distribution;
my %ts_distribution;
my %cp_distribution;
my %bv_distribution;
my %sd_distribution;
my %mf_distribution;
my %mw_distribution;
my %dm_distribution;

my %transaction_name;
$transaction_name{ "0" } = "trade_order";
$transaction_name{ "1" } = "trade_result";
$transaction_name{ "2" } = "trade_lookup";
$transaction_name{ "3" } = "trade_update";
$transaction_name{ "4" } = "trade_status";
$transaction_name{ "5" } = "customer_position";
$transaction_name{ "6" } = "broker_volume";
$transaction_name{ "7" } = "security_detail";
$transaction_name{ "8" } = "market_feed";
$transaction_name{ "9" } = "market_watch";
$transaction_name{ "D" } = "data_maintenance";

$transaction_name{ "0R" } = "trade_order";
$transaction_name{ "1R" } = "trade_result";
$transaction_name{ "2R" } = "trade_lookup";
$transaction_name{ "3R" } = "trade_update";
$transaction_name{ "4R" } = "trade_status";
$transaction_name{ "5R" } = "customer_position";
$transaction_name{ "6R" } = "broker_volume";
$transaction_name{ "7R" } = "security_detail";
$transaction_name{ "8R" } = "market_feed";
$transaction_name{ "9R" } = "market_watch";
$transaction_name{ "DR" } = "data_maintenance";

$transaction_name{ "E" } = "unknown error";

#
# Open separate files because the range of data varies by transaction.
#
open( TO_FILE, ">$outdir/to_tran.data" );
open( TR_FILE, ">$outdir/tr_tran.data" );
open( TL_FILE, ">$outdir/tl_tran.data" );
open( TU_FILE, ">$outdir/tu_tran.data" );
open( TS_FILE, ">$outdir/ts_tran.data" );
open( CP_FILE, ">$outdir/cp_tran.data" );
open( BV_FILE, ">$outdir/bv_tran.data" );
open( SD_FILE, ">$outdir/sd_tran.data" );
open( MF_FILE, ">$outdir/mf_tran.data" );
open( MW_FILE, ">$outdir/mw_tran.data" );
open( DM_FILE, ">$outdir/dm_tran.data" );

my $current_time;
my $start_time;
my $steady_state_start_time = 0;
my $previous_time;
my $total_response_time;
my $total_transaction_count;
my $response_time;

my %current_transaction_count;
my %rollback_count;
my %transaction_count;
my %transaction_response_time;

$current_transaction_count{ '0' } = 0;
$current_transaction_count{ '1' } = 0;
$current_transaction_count{ '2' } = 0;
$current_transaction_count{ '3' } = 0;
$current_transaction_count{ '4' } = 0;
$current_transaction_count{ '5' } = 0;
$current_transaction_count{ '6' } = 0;
$current_transaction_count{ '7' } = 0;
$current_transaction_count{ '8' } = 0;
$current_transaction_count{ '9' } = 0;
$current_transaction_count{ 'D' } = 0;

$rollback_count{ '0' } = 0;
$rollback_count{ '1' } = 0;
$rollback_count{ '2' } = 0;
$rollback_count{ '3' } = 0;
$rollback_count{ '4' } = 0;
$rollback_count{ '5' } = 0;
$rollback_count{ '6' } = 0;
$rollback_count{ '7' } = 0;
$rollback_count{ '8' } = 0;
$rollback_count{ '9' } = 0;
$rollback_count{ 'D' } = 0;

#
# Transaction counts for the steady state portion of the test.
#
$transaction_count{ '0' } = 0;
$transaction_count{ '1' } = 0;
$transaction_count{ '2' } = 0;
$transaction_count{ '3' } = 0;
$transaction_count{ '4' } = 0;
$transaction_count{ '5' } = 0;
$transaction_count{ '6' } = 0;
$transaction_count{ '7' } = 0;
$transaction_count{ '8' } = 0;
$transaction_count{ '9' } = 0;
$transaction_count{ 'D' } = 0;

#
# Read the data directly from the log file and handle it on the fly.
#
print CSV "0 0 0 0 0 0\n";
while ( defined( $line = <FH> ) ) {
	chomp $line;
	my @word = split /,/, $line;

	if (scalar(@word) == 4) {
		#
		# Count transactions per second based on transaction type.
		#
		$current_time = $word[0];
		my $response_time = $word[2];
		#
		# Save the very first start time in the log.
		#
		unless ( $start_time ) {
			$start_time = $previous_time = $current_time;
		}
		if ( $current_time >= ( $previous_time + $sample_length ) ) {
			print CSV "$elapsed_time "
				. "$current_transaction_count{ '0' } "
				. "$current_transaction_count{ '1' } "
				. "$current_transaction_count{ '2' } "
				. "$current_transaction_count{ '3' } "
				. "$current_transaction_count{ '4' } "
				. "$current_transaction_count{ '5' } "
				. "$current_transaction_count{ '6' } "
				. "$current_transaction_count{ '7' } "
				. "$current_transaction_count{ '8' } "
				. "$current_transaction_count{ '9' } "
				. "$current_transaction_count{ 'D' }\n";

			++$elapsed_time;
			$previous_time = $current_time;

			#
			# Reset counters for the next sample interval.
			#
			$current_transaction_count{ '0' } = 0;
			$current_transaction_count{ '1' } = 0;
			$current_transaction_count{ '2' } = 0;
			$current_transaction_count{ '3' } = 0;
			$current_transaction_count{ '4' } = 0;
			$current_transaction_count{ '5' } = 0;
			$current_transaction_count{ '6' } = 0;
			$current_transaction_count{ '7' } = 0;
			$current_transaction_count{ '8' } = 0;
			$current_transaction_count{ '9' } = 0;
			$current_transaction_count{ 'D' } = 0;
		}

		#
		# Determine response time distributions for each transaction
		# type.  Also determine response time for a transaction when
		# it occurs during the run.  Calculate response times for
		# each transaction;
		#
		my $time;
		$time = sprintf("%.2f", $response_time );
		my $x_time = ($word[ 0 ] - $start_time) / 60;

		if ( $word[ 1 ] eq '0' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '0' };
				$transaction_response_time{ '0' } += $response_time;
				push @trade_order_response_time, $response_time;
				++$current_transaction_count{ '0' };
			}
			++$to_distribution{ $time };
			print TO_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '1' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '1' };
				$transaction_response_time{ '1' } += $response_time;
				push @trade_result_response_time, $response_time;
				++$current_transaction_count{ '1' };
			}
			++$tr_distribution{ $time };
			print TR_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '2' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '2' };
				$transaction_response_time{ '2' } += $response_time;
				push @trade_lookup_response_time, $response_time;
				++$current_transaction_count{ '2' };
			}
			++$tl_distribution{ $time };
			print TL_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '3' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '3' };
				$transaction_response_time{ '3' } += $response_time;
				push @trade_update_response_time, $response_time;
				++$current_transaction_count{ '3' };
			}
			++$tu_distribution{ $time };
			print TU_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '4' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '4' };
				$transaction_response_time{ '4' } += $response_time;
				push @trade_status_response_time, $response_time;
				++$current_transaction_count{ '4' };
			}
			++$ts_distribution{ $time };
			print TS_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '5' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '5' };
				$transaction_response_time{ '5' } += $response_time;
				push @customer_position_response_time, $response_time;
				++$current_transaction_count{ '5' };
			}
			++$cp_distribution{ $time };
			print CP_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '6' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '6' };
				$transaction_response_time{ '6' } += $response_time;
				push @broker_volume_response_time, $response_time;
				++$current_transaction_count{ '6' };
			}
			++$bv_distribution{ $time };
			print BV_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '7' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '7' };
				$transaction_response_time{ '7' } += $response_time;
				push @security_detail_response_time, $response_time;
				++$current_transaction_count{ '7' };
			}
			++$sd_distribution{ $time };
			print SD_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '8' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '8' };
				$transaction_response_time{ '8' } += $response_time;
				push @market_feed_response_time, $response_time;
				++$current_transaction_count{ '8' };
			}
			++$mf_distribution{ $time };
			print MF_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '9' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ '9' };
				$transaction_response_time{ '9' } += $response_time;
				push @market_watch_response_time, $response_time;
				++$current_transaction_count{ '9' };
			}
			++$mw_distribution{ $time };
			print MW_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq 'D' ) {
			unless ($steady_state_start_time == 0) {
				++$transaction_count{ 'D' };
				$transaction_response_time{ 'D' } += $response_time;
				push @data_maintenance_response_time, $response_time;
				++$current_transaction_count{ 'D' };
			}
			++$dm_distribution{ $time };
			print DM_FILE "$x_time $response_time\n";
		} elsif ( $word[ 1 ] eq '0R' ) {
			++$rollback_count{ '0' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '1R' ) {
			++$rollback_count{ '1' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '2R' ) {
			++$rollback_count{ '2' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '3R' ) {
			++$rollback_count{ '3' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '4R' ) {
			++$rollback_count{ '4' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '5R' ) {
			++$rollback_count{ '5' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '6R' ) {
			++$rollback_count{ '6' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '7R' ) {
			++$rollback_count{ '7' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '8R' ) {
			++$rollback_count{ '8' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq '9R' ) {
			++$rollback_count{ '9' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq 'DR' ) {
			++$rollback_count{ 'D' } unless ($steady_state_start_time == 0);
		} elsif ( $word[ 1 ] eq 'E' ) {
			++$errors;
			++$error_count{ $word[ 3 ] };
		}
		
		#
		# Count unknown errors.
		#
		unless ($word[ 1 ] eq 'E' ) {
			++$data{ $word[ 3 ] };
			$last_time{ $word[ 3 ] } = $word[ 0 ];
		}

		$total_response_time += $response_time;
		++$total_transaction_count;
	} elsif (scalar(@word) == 2) {
		#
		# Look for that 'START' marker to determine the end of the rampup time
		# and to calculate the average throughput from that point to the end
		# of the test.
		#
		$steady_state_start_time = $word[0];
	}
}
close( FH );
close( CSV );
close( TO_FILE );
close( TR_FILE );
close( TL_FILE );
close( TU_FILE );
close( TS_FILE );
close( CP_FILE );
close( BV_FILE );
close( SD_FILE );
close( MF_FILE );
close( MW_FILE );
close( DM_FILE );

#
# Do statistics.
#
my $tid;
my $stat = Statistics::Descriptive::Full->new();

foreach $tid (keys %data) {
	$stat->add_data( $data{ $tid } );
}
my $count = $stat->count();
my $mean = $stat->mean();
my $var  = $stat->variance();
my $stddev = $stat->standard_deviation();
my $median = $stat->median();
my $min = $stat->min();
my $max = $stat->max();

#
# Display the data.
#
if ( $verbose ) {
	printf( "%10s %4s %12s\n", "----------", "-----",
		"------------ ------" );
	printf( "%10s %4s %12s\n", "Thread ID", "Count",
		"Last Txn (s) Errors" );
	printf( "%10s %4s %12s\n", "----------", "-----",
		"------------ ------" );
}
foreach $tid ( keys %data ) {
	$stat->add_data( $data{ $tid } );
	$error_count{ $tid } = 0 unless ( $error_count{ $tid } );
	$last_time{ $tid } = $current_time + 1 unless ( $last_time{ $tid } );
	printf( "%9d %5d %12d %6d\n", $tid, $data{ $tid },
		$current_time - $last_time{ $tid }, $error_count{ $tid } )
		if ( $verbose );
}
if ( $verbose ) {
	printf( "%10s %4s %12s\n", "----------", "-----",
		"------------ ------" );
	print "\n";
	print "Statistics Over All Transactions:\n";
	printf( "run length = %d seconds\n", $current_time - $start_time );
	printf( "count = %d\n", $count );
	printf( "mean = %4.2f\n", $mean );
	printf( "min = %4.2f\n", $min );
	printf( "max = %4.2f\n", $max );
	printf( "median = %4.2f\n", $median );
	printf( "standard deviation = %4.2f\n", $stddev ) if ( $count > 1 );

	print "\n";
}

if ( $verbose ) {
	print "Trade Order Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/trade_order.data" );
foreach my $time ( sort keys %to_distribution  ) {
	printf( "%8s %5d\n", $time, $to_distribution{ $time } ) if ( $verbose );
	print FILE "$time $to_distribution{ $time }\n"
		if ( $to_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Trade Result Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/trade_result.data" );
foreach my $time ( sort keys %tr_distribution  ) {
	printf( "%8s %5d\n", $time, $tr_distribution{ $time } ) if ( $verbose );
	print FILE "$time $tr_distribution{ $time }\n"
		if ( $tr_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Trade Lookup Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/trade_lookup.data" );
foreach my $time ( sort keys %tl_distribution  ) {
	printf( "%8s %5d\n", $time, $tl_distribution{ $time } ) if ( $verbose );
	print FILE "$time $tl_distribution{ $time }\n"
		if ( $tl_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Trade Update Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/trade_update.data" );
foreach my $time ( sort keys %tu_distribution  ) {
	printf( "%8s %5d\n", $time, $tu_distribution{ $time } ) if ( $verbose );
	print FILE "$time $tu_distribution{ $time }\n"
		if ( $tu_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Trade Status Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/trade_status.data" );
foreach my $time ( sort keys %ts_distribution  ) {
	printf( "%8s %5d\n", $time, $ts_distribution{ $time } ) if ( $verbose );
	print FILE "$time $ts_distribution{ $time }\n"
		if ( $ts_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Customer Position Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/customer_position.data" );
foreach my $time ( sort keys %cp_distribution  ) {
	printf( "%8s %5d\n", $time, $cp_distribution{ $time } ) if ( $verbose );
	print FILE "$time $cp_distribution{ $time }\n"
		if ( $cp_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Broker Volume Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/broker_volume.data" );
foreach my $time ( sort keys %bv_distribution  ) {
	printf( "%8s %5d\n", $time, $bv_distribution{ $time } ) if ( $verbose );
	print FILE "$time $bv_distribution{ $time }\n"
		if ( $bv_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Security Detail Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/security_detail.data" );
foreach my $time ( sort keys %sd_distribution  ) {
	printf( "%8s %5d\n", $time, $sd_distribution{ $time } ) if ( $verbose );
	print FILE "$time $sd_distribution{ $time }\n"
		if ( $sd_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Market Feed Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/market_feed.data" );
foreach my $time ( sort keys %mf_distribution  ) {
	printf( "%8s %5d\n", $time, $mf_distribution{ $time } ) if ( $verbose );
	print FILE "$time $mf_distribution{ $time }\n"
		if ( $mf_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Market Watch Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/market_watch.data" );
foreach my $time ( sort keys %mw_distribution  ) {
	printf( "%8s %5d\n", $time, $mw_distribution{ $time } ) if ( $verbose );
	print FILE "$time $mw_distribution{ $time }\n"
		if ( $mw_distribution{ $time } );
}
close( FILE );
if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
	print "\n";

	print "Data Maintenance Response Time Distribution\n";
	printf( "%8s %5s\n", "--------", "-----" );
	printf( "%8s %5s\n", "Time (s)", "Count" );
	printf( "%8s %5s\n", "--------", "-----" );
}
open( FILE, ">$outdir/data_maintenance.data" );
foreach my $time ( sort keys %dm_distribution  ) {
	printf( "%8s %5d\n", $time, $dm_distribution{ $time } ) if ( $verbose );
	print FILE "$time $dm_distribution{ $time }\n"
		if ( $dm_distribution{ $time } );
}
close( FILE );

if ( $verbose ) {
	printf( "%8s %5s\n", "--------", "-----" );
}


#
# Create gnuplot input file and generate the charts.
#
chdir $outdir;
foreach my $transaction ( @transactions ) {
	my $filename = "$transaction.input";
	open( FILE, ">$filename" )
		or die "cannot open $filename\n";
	print FILE "plot \"$transaction.data\" using 1:2 title \"$transaction\" \n";
	print FILE "set term png small\n";
	print FILE "set output \"$transaction.png\"\n";
	print FILE "set grid xtics ytics\n";
	print FILE "set xlabel \"Response Time (seconds)\"\n";
	print FILE "set ylabel \"Count\"\n";
	print FILE "replot\n";
	close( FILE );
	system "gnuplot $transaction.input";
}

foreach my $transaction ( @xtran ) {
	my $filename = "$transaction" . "-bar.input";
	open( FILE, ">$filename" )
		or die "cannot open $filename\n";
	print FILE "plot \"$transaction.data\" using 1:2 title \"$transaction\" \n";
	print FILE "set term png small\n";
	print FILE "set output \"$transaction" . "_bar.png\"\n";
	print FILE "set grid xtics ytics\n";
	print FILE "set xlabel \"Elapsed Time (Minutes)\"\n";
	print FILE "set ylabel \"Response Time (Seconds)\"\n";
	print FILE "replot\n";
	close( FILE );
	system "gnuplot $filename";
}

#
# Determine 90th percentile response times for each transaction.
#
@trade_order_response_time = sort(@trade_order_response_time);
@trade_result_response_time = sort(@trade_result_response_time);
@trade_lookup_response_time = sort(@trade_lookup_response_time);
@trade_update_response_time = sort(@trade_update_response_time);
@trade_status_response_time = sort(@trade_status_response_time);
@customer_position_response_time = sort(@customer_position_response_time);
@broker_volume_response_time = sort(@broker_volume_response_time);
@security_detail_response_time = sort(@security_detail_response_time);
@market_feed_response_time = sort(@market_feed_response_time);
@market_watch_response_time = sort(@market_watch_response_time);
@data_maintenance_response_time = sort(@data_maintenance_response_time);

#
# Get the index for the 90th percentile point.
#
my $trade_order90index = $transaction_count{'0'} * 0.90;
my $trade_result90index = $transaction_count{'1'} * 0.90;
my $trade_lookup90index = $transaction_count{'2'} * 0.90;
my $trade_update90index = $transaction_count{'3'} * 0.90;
my $trade_status90index = $transaction_count{'4'} * 0.90;
my $customer_position90index = $transaction_count{'5'} * 0.90;
my $broker_volume90index = $transaction_count{'6'} * 0.90;
my $security_detail90index = $transaction_count{'7'} * 0.90;
my $market_feed90index = $transaction_count{'8'} * 0.90;
my $market_watch90index = $transaction_count{'9'} * 0.90;
my $data_maintenance90index = $transaction_count{'D'} * 0.90;

my %response90th;

my $floor;
my $ceil;

$floor = floor($trade_order90index);
$ceil = ceil($trade_order90index);
if ($floor == $ceil) {
	$response90th{'0'} = $trade_order_response_time[$trade_order90index];
} else {
	$response90th{'0'} = ($trade_order_response_time[$floor] +
			$trade_order_response_time[$ceil]) / 2;
}

$floor = floor($trade_result90index);
$ceil = ceil($trade_result90index);
if ($floor == $ceil) {
	$response90th{'1'} = $trade_result_response_time[$trade_result90index];
} else {
	$response90th{'1'} = ($trade_result_response_time[$floor] +
			$trade_result_response_time[$ceil]) / 2;
}

$floor = floor($trade_lookup90index);
$ceil = ceil($trade_lookup90index);
if ($floor == $ceil) {
	$response90th{'2'} = $trade_lookup_response_time[$trade_lookup90index];
} else {
	$response90th{'2'} = ($trade_lookup_response_time[$floor] +
			$trade_lookup_response_time[$ceil]) / 2;
}

$floor = floor($trade_update90index);
$ceil = ceil($trade_update90index);
if ($floor == $ceil) {
	$response90th{'3'} = $trade_update_response_time[$trade_update90index];
} else {
	$response90th{'3'} = ($trade_update_response_time[$floor] +
			$trade_update_response_time[$ceil]) / 2;
}

$floor = floor($trade_status90index);
$ceil = ceil($trade_status90index);
if ($floor == $ceil) {
	$response90th{'4'} = $trade_status_response_time[$trade_status90index];
} else {
	$response90th{'4'} = ($trade_status_response_time[$floor] +
			$trade_status_response_time[$ceil]) / 2;
}

$floor = floor($customer_position90index);
$ceil = ceil($customer_position90index);
if ($floor == $ceil) {
	$response90th{'5'} = $customer_position_response_time[$customer_position90index];
} else {
	$response90th{'5'} = ($customer_position_response_time[$floor] +
			$customer_position_response_time[$ceil]) / 2;
}

$floor = floor($broker_volume90index);
$ceil = ceil($broker_volume90index);
if ($floor == $ceil) {
	$response90th{'6'} = $broker_volume_response_time[$broker_volume90index];
} else {
	$response90th{'6'} = ($broker_volume_response_time[$floor] +
			$broker_volume_response_time[$ceil]) / 2;
}

$floor = floor($security_detail90index);
$ceil = ceil($security_detail90index);
if ($floor == $ceil) {
	$response90th{'7'} = $security_detail_response_time[$security_detail90index];
} else {
	$response90th{'7'} = ($security_detail_response_time[$floor] +
			$security_detail_response_time[$ceil]) / 2;
}

$floor = floor($market_feed90index);
$ceil = ceil($market_feed90index);
if ($floor == $ceil) {
	$response90th{'8'} = $market_feed_response_time[$market_feed90index];
} else {
	$response90th{'8'} = ($market_feed_response_time[$floor] +
			$market_feed_response_time[$ceil]) / 2;
}

$floor = floor($market_watch90index);
$ceil = ceil($market_watch90index);
if ($floor == $ceil) {
	$response90th{'9'} = $market_watch_response_time[$market_watch90index];
} else {
	$response90th{'9'} = ($market_watch_response_time[$floor] +
			$market_watch_response_time[$ceil]) / 2;
}

$floor = floor($data_maintenance90index);
$ceil = ceil($data_maintenance90index);
if ($floor == $ceil) {
	$response90th{'D'} = $data_maintenance_response_time[$data_maintenance90index];
} else {
	$response90th{'D'} = ($data_maintenance_response_time[$floor] +
			$data_maintenance_response_time[$ceil]) / 2;
}

#
# Calculate the actual mix of transactions.
#
printf("                              Response Time (s)\n");
printf(" Transaction                %%    Average :    90th %%        Total        Rollbacks      %%\n");
printf("-----------------       -----  ---------------------  -----------  ---------------  -----\n");
foreach my $idx ('0', '1', '2', '3', '4','5','6','7','8','9','D') {
	if ($transaction_count{$idx} == 0) {
		printf("%12s        0.00          N/A                      0                0   0.00\n", $transaction{$idx});
	} else {
		printf("%12s       %5.2f  %9.3f : %9.3f  %11d  %15d  %5.2f\n",
				$transaction{$idx},
				($transaction_count{$idx} + $rollback_count{$idx}) /
						$total_transaction_count * 100.0,
				$transaction_response_time{$idx} / $transaction_count{$idx},
				$response90th{$idx},
				$transaction_count{$idx} + $rollback_count{$idx},
				$rollback_count{$idx},
				$rollback_count{$idx} /
						($rollback_count{$idx} + $transaction_count{$idx}) *
						100.0);
	}
}

#
# Calculated the number of transactions per second.
#
my $tps = $transaction_count{'1'} / ($current_time - $start_time);
printf("\n");
printf("%0.2f trade-result transactions per second (TRTPS)\n", $tps);
printf("%0.1f minute duration\n", ($current_time - $start_time) / 60.0);
printf("%d total unknown errors\n", $errors);
printf("%d second(s) ramping up\n", $steady_state_start_time - $start_time);
printf("\n");
