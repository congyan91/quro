/*
 * BaseInterface.h
 * Base class for emulator-SUT interface
 *
 * 2006 Rilson Nascimento
 *
 * 13 August 2006
 */

#ifndef BASE_INTERFACE_H
#define BASE_INTERFACE_H

#include "locking.h"

using namespace TPCE;

class CBaseInterface
{
protected:
	void TalkToSUT(PMsgDriverBrokerage pRequest);
	void LogErrorMessage(const string sErr);

	char*		m_szBHAddress;
	int			m_iBHlistenPort;
	CMutex*		m_pLogLock;
	CMutex*		m_pMixLock;
	ofstream*	m_pfLog;	// error log file
	ofstream*	m_pfMix;	// mix log file

private:
	CSocket	*sock;
	void LogResponseTime(int iStatus, int iTxnType, double dRT);
	
public:

	CBaseInterface(char* addr, const int iListenPort, ofstream* pflog,
			ofstream* pfmix, CMutex* pLogLock, CMutex* pMixLock);
	~CBaseInterface(void);
	void Connect();
	void Disconnect();
};

#endif	// BASE_INTERFACE_H
