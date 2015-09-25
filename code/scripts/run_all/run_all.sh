cp $HOME/bin/orig_payment_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_payment_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_orig_payment.sh

cp $HOME/bin/orig_neworder_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_neworder_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_orig_neworder.sh

cp $HOME/bin/orig_mix_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_mix_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_orig_mix.sh

cp $HOME/bin/orig_all_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_all_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_orig_all.sh


cp $HOME/bin/reorder_payment_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_payment_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_reorder_payment.sh

cp $HOME/bin/reorder_neworder_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_neworder_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_reorder_neworder.sh

cp $HOME/bin/reorder_mix_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_mix_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_reorder_mix.sh

cp $HOME/bin/reorder_all_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_all_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_reorder_all.sh


cp $HOME/bin/storedproc_payment_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_payment_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_storedproc_payment.sh

cp $HOME/bin/storedproc_neworder_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_neworder_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_storedproc_neworder.sh

cp $HOME/bin/storedproc_all_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_all_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_storedproc_all.sh

cp $HOME/bin/storedproc_mix_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_mix_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-db
cd ../run_all
./autorun_storedproc_mix.sh

#================================================
#================================================

cp $HOME/bin/orig_payment_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_payment_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_orig_payment.sh

cp $HOME/bin/orig_neworder_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_neworder_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_orig_neworder.sh

cp $HOME/bin/orig_mix_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_mix_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_orig_mix.sh

cp $HOME/bin/orig_all_bin/TPCCMain $HOME/bin/
cp $HOME/bin/orig_all_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_orig_all.sh


cp $HOME/bin/reorder_payment_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_payment_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_reorder_payment.sh

cp $HOME/bin/reorder_neworder_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_neworder_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_reorder_neworder.sh

cp $HOME/bin/reorder_mix_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_mix_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_reorder_mix.sh

cp $HOME/bin/reorder_all_bin/TPCCMain $HOME/bin/
cp $HOME/bin/reorder_all_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_reorder_all.sh


cp $HOME/bin/storedproc_payment_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_payment_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_storedproc_payment.sh

cp $HOME/bin/storedproc_neworder_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_neworder_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_storedproc_neworder.sh

cp $HOME/bin/storedproc_all_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_all_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_storedproc_all.sh

cp $HOME/bin/storedproc_mix_bin/TPCCMain $HOME/bin/
cp $HOME/bin/storedproc_mix_bin/DriverMain $HOME/bin/
cd ../mysql
./tpcc-mysql-build-large-db
cd ../run_all
./autorun_scale_storedproc_mix.sh

