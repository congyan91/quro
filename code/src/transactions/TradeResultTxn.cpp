#include "DBConnection.h"
#include "TradeResultDB.h"

#ifndef DB_PGSQL

#ifdef PROFILE_EACH_QUERY
#define ADD_PROFILE_NODE(f, q, commit) \
				gettimeofday(&t2, NULL); \
				add_profile_node(f, q, difftimeval(t2, t1), commit);
#endif

#define FAIL_MSG(msg) \
				string fail_msg(msg); \
				fail_msg.append(query); \
				if (r==2) fail_msg.append("\tempty result"); \
				throw fail_msg.c_str();

void CDBConnection::execute(PTradeResultTxnInput pIn,
		PTradeResultTxnOutput pOut)
{
	char query[4096];
	sql_result_t result;
	sql_result_t result_t;
	int length;
	char* val;
	int r = 0;

	long unsigned int trade_id = pIn->trade_id;
	double trade_price = pIn->trade_price;

	long unsigned int acct_id;
	long int trade_qty;
	double charge;
	int is_lifo;
	char type_id[10] = {0};
	char symbol[20] = {0};
	char type_name[20] = {0};

	int trade_is_cash;
	bool type_is_sell = false;
	bool type_is_market = false;
	long int hs_qty;
	long unsigned int hold_id;
	long int hold_qty;
	double hold_price;
	long int needed_qty;
	double buy_value = 0.0;
	double sell_value = 0.0;
	char now_dts[100]={0};

	double tax_rate;
	long broker_id;
	long cust_id;
	int tax_status;
	TIMESTAMP_STRUCT trade_dts;
	char st_completed_id[5] = "CMPT";
	double tax_amount = 0.0;

	char s_name[200] = {0};
	float comm_rate;
	double comm_amount = 0.0;
	char sec_ex_id[20]={0};
	double acct_bal;
	int cust_tier;

	char cash_type[10]={0};
	double se_amount;
	TIMESTAMP_STRUCT due_date;

	unsigned int before_qty;
	unsigned int after_qty;
	bool insert_holding_his = false;
	bool delete_holding_summary = false;

//--------------------Frame 1-----------------
//	TRADE_RESULT_F1Q1;

	{
		acct_id = pIn->acct_id;
		strcpy(type_id, pIn->type_id);
		strcpy(symbol, pIn->symbol);
		trade_qty = pIn->trade_qty;
		is_lifo = pIn->is_lifo;
		trade_is_cash = pIn->trade_is_cash;
		charge = pIn->charge;
	}

	TRADE_RESULT_F1Q2;

	TRADE_RESULT_F1Q3;
//-------------FRAME 2--------------
	TRADE_RESULT_F2Q0;

//	TRADE_RESULT_F2Q1;

	sscanf(now_dts, "%hd-%hd-%hd %hd:%hd:%hd.%*d",
			&trade_dts.year,
			&trade_dts.month,
			&trade_dts.day,
			&trade_dts.hour,
			&trade_dts.minute,
			&trade_dts.second);

	bool update_holding_summary_3 = false;
	bool update_holding_summary_14 = false;
	long tmp_hs_qty;
	long tmp_trade_qty;
	if(type_is_sell){
			if(hs_qty == 0){
				TRADE_RESULT_F2Q2;
			}else if(hs_qty != trade_qty){
				update_holding_summary_3 = true;
				tmp_hs_qty = hs_qty;
				tmp_trade_qty = trade_qty;
//				TRADE_RESULT_F2Q3;
			}

			needed_qty = trade_qty;

			size_t num_rows = 0;
			size_t cnt = 0;
			if(hs_qty > 0){
					if(is_lifo){
						TRADE_RESULT_F2Q4;
					}else{
						TRADE_RESULT_F2Q5;
					}
					r = 0;
					while(needed_qty > 0 && cnt < num_rows){
							dbt5_sql_fetchrow(&result_t);
							cnt++;

							hold_id = atol(dbt5_sql_getvalue(&result_t, 0, length));
							hold_qty = atol(dbt5_sql_getvalue(&result_t, 1, length));
							hold_price = atof(dbt5_sql_getvalue(&result_t, 2, length));

							if(hold_qty > needed_qty){
									
									TRADE_RESULT_F2Q6;
									
									TRADE_RESULT_F2Q7;
									
									buy_value = buy_value + (needed_qty * hold_price);
									sell_value = sell_value + (needed_qty * trade_price);
									needed_qty = 0;
							}else{
									
									TRADE_RESULT_F2Q8;
									
									TRADE_RESULT_F2Q9;
									delete_holding_summary = true;
									
									buy_value = buy_value + (hold_qty * hold_price);
									sell_value = sell_value + (hold_qty * trade_price);
									needed_qty = needed_qty - hold_qty;
							}
					}
			}
			if(needed_qty > 0){
				TRADE_RESULT_F2Q10;

				TRADE_RESULT_F2Q11;

			}else if(hs_qty == trade_qty){
				TRADE_RESULT_F2Q12;
				delete_holding_summary = true;
			}
	}
	//type_is_market
	else{
			if(hs_qty == 0){
				TRADE_RESULT_F2Q13;
			}else{
				update_holding_summary_14 = true;
				tmp_hs_qty = hs_qty;
				tmp_trade_qty = trade_qty;
//				TRADE_RESULT_F2Q14;
			}
			size_t num_rows = 0;
			size_t cnt = 0;

			if(hs_qty < 0){
					if(is_lifo){
						TRADE_RESULT_F2Q15;
					}else{
						TRADE_RESULT_F2Q16;
					}
					while(needed_qty>0 && cnt<num_rows){
							dbt5_sql_fetchrow(&result_t);
							cnt++;
							hold_id = atol(dbt5_sql_getvalue(&result_t, 0, length));
							hold_qty = atol(dbt5_sql_getvalue(&result_t, 1, length));
							hold_price = atof(dbt5_sql_getvalue(&result_t, 2, length));
							if(hold_qty > needed_qty){
									TRADE_RESULT_F2Q17;
									
									TRADE_RESULT_F2Q18;
									
									buy_value = buy_value + (needed_qty * hold_price);
									sell_value = sell_value + (needed_qty * trade_price);
									needed_qty = 0;
							}else{
									TRADE_RESULT_F2Q19;

									TRADE_RESULT_F2Q20;
									delete_holding_summary = true;

									hold_qty = (-1)*hold_qty;
									buy_value = buy_value + (hold_qty * hold_price);
									sell_value = sell_value + (hold_qty * trade_price);
									needed_qty = needed_qty - hold_qty;
							}
					}
			}
			if(needed_qty > 0){
					TRADE_RESULT_F2Q21;

					TRADE_RESULT_F2Q22;

			}else if((-1)*hs_qty == trade_qty){
					TRADE_RESULT_F2Q23;
					delete_holding_summary = true;
			}
	}


//----------------Frame 3---------------
	if((tax_status == 1 || tax_status == 2) && sell_value > buy_value){
			sprintf(query, TRADE_RESULT3_1, cust_id);

			TRADE_RESULT_F3Q1;

			TRADE_RESULT_F3Q2;

			tax_amount = tax_rate*(sell_value - buy_value);
}

//---------------------Frame 4----------------

	TRADE_RESULT_F4Q1;

//	TRADE_RESULT_F4Q2; 

//	TRADE_RESULT_F4Q3; 
//--------------------Frame 5--------------------
	comm_amount = ( comm_rate / 100.00 ) * ( trade_qty * trade_price );
  // round up for correct precision (cents only)
  comm_amount = (double)((int)(100.00 * comm_amount + 0.5)) / 100.00;

//	sprintf(now_dts, "%d-%d-%d %d:%d:%d", trade_dts.year, trade_dts.month, trade_dts.day, trade_dts.hour, trade_dts.minute, trade_dts.second);

	TRADE_RESULT_F5Q1;

	TRADE_RESULT_F5Q2;

//	TRADE_RESULT_F5Q3;
//-----------------Frame 6--------------------
	if (type_is_sell)
  {
      se_amount = trade_qty * trade_price
                                        - charge
                                        - comm_amount;
  }
  else
  {
      se_amount = -1 * ( trade_qty * trade_price
                                                + charge
                                                + comm_amount);
  }

  // withhold tax only for certain account tax status
  if (tax_status == 1)
  {
      se_amount -= tax_amount;
  }

	if(trade_is_cash){
			sprintf(cash_type, "Cash Account");
	}else{
			sprintf(cash_type, "Margin");
	}

	char due_dts[20]={0};
	CDateTime due_date_time(&trade_dts);
	due_date_time.Add(2, 0);
	due_date_time.SetHMS(0,0,0,0);
	due_date_time.GetTimeStamp(&due_date);

	sprintf(due_dts, "%d-%d-%d %d:%d:%d", due_date.year, due_date.month, due_date.day, due_date.hour, due_date.minute, due_date.second);

	TRADE_RESULT_F6Q1;

//	sprintf(now_dts, "%d-%d-%d %d:%d:%d", trade_dts.year, trade_dts.month, trade_dts.day, trade_dts.hour, trade_dts.minute, trade_dts.second);

	if(trade_is_cash){
//			TRADE_RESULT_F6Q2; 
			TRADE_RESULT_F6Q3;
			TRADE_RESULT_F6Q4;
	}
//=================
	//if(insert_holding_his){
	//	TRADE_RESULT_F2Q4a;
	//}
//=================


	TRADE_RESULT_F2Q1;
	hs_qty = tmp_hs_qty;
	long ex_trade_qty = trade_qty;
	trade_qty = tmp_trade_qty;
	if(update_holding_summary_3 && delete_holding_summary == false){
		TRADE_RESULT_F2Q3;
	}
	else if(update_holding_summary_14 && delete_holding_summary == false){
		TRADE_RESULT_F2Q14;
	}
	trade_qty = ex_trade_qty;

//	TRADE_RESULT_F5Q1;

	TRADE_RESULT_F4Q2; 

	TRADE_RESULT_F4Q3; 
	TRADE_RESULT_F5Q3;
	if(trade_is_cash){
		TRADE_RESULT_F6Q2;
	}

//---------------set output-------------
	pOut->acct_id = acct_id;
	pOut->acct_bal = acct_bal;
	pOut->load_unit = cust_id;
}
#endif
