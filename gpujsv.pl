#!/usr/bin/perl

use strict;
use warnings;
no warnings qw/uninitialized/;

use Env qw(SGE_ROOT);
use lib "$SGE_ROOT/util/resources/jsv";
use JSV qw( :DEFAULT jsv_send_env jsv_log_info jsv_log_error);


jsv_on_start(sub {
   jsv_send_env();
});

jsv_on_verify(sub {
   my %params = jsv_get_param_hash();
   my $do_correct = 0;
   my $do_wait = 0;
   if (exists $params{q_hard}){
     foreach my $key ( keys %{$params{q_hard}} )  {
        if ( $key=~/gpu/) {
          jsv_add_env('QRSH_WRAPPER','/cm/shared/apps/sge/current/util/gpu_wrapper.sh');
          jsv_sub_add_param('l_hard', 'rcpus',1);
          # for fractional gpu resuest? jsv_sub_add_param('l_hard', 'ngpus',1);
          #jsv_set_param('p',200);
          #jsv_sub_add_param('l_hard', 'ngpus',1);
          if (exists $params{l_hard}) {
            jsv_sub_add_param('l_hard', 'ngpus',1);
            if (exists $params{l_hard}{ngpus}) {
              my $lgpus = $params{l_hard}{ngpus};
              if (($lgpus) > 1) {
                 jsv_sub_add_param('l_hard', 'ngpus',1);
                 #jsv_reject('ngpus is <=1');
                 #return;
              }
            } else { #user forget to set ngpus=1?
              jsv_sub_add_param('l_hard', 'ngpus',1);
            }
          } else { #user forget to set "-l"?
            jsv_sub_add_param('l_hard', 'ngpus',1);
          }
          $do_correct = 1;
          last;
        }

        if ( $key=~/cpu/) {
          jsv_sub_add_param('l_hard', 'rcpus',10);

          if ( $params{pe_name} =~ 'omp') { #multi-threading#now /etc/profile.d/numpy.sh set all to 1. Users need to set in job script.
            my $lslots = $params{pe_min};
            jsv_add_env('OMP_NUM_THREADS',$lslots);
            jsv_log_error('OMP_NUM_THREADS is required to to be set for OMP jobs.');#, $lslots, '. Otherwise, it is set to be 1 by default.);
          }
          $do_correct = 1;
          last;
        }

     }
   }

   if ($do_wait) {
      jsv_reject_wait('Job is rejected. It might be submitted later.');
   } elsif ($do_correct) {
      jsv_correct('Job was modified before it was accepted');
   } else {
      jsv_accept('Job is accepted');
   }
}); 

jsv_main();
