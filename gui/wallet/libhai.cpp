#include "libhai.h"

Libhai::Libhai(QObject *parent) : QObject(parent)
{
    InitLib();

    connect(&m_timer, &QTimer::timeout, this, &Libhai::timeout);
    connect(&m_wait, &QTimer::timeout, this, &Libhai::waitout);
    m_timer.setInterval(3000);
    m_wait.setInterval(30000);

    this->start();
}

Libhai::~Libhai()
{
    m_timer.stop();

    finish();
}

void Libhai::timeout()
{
    static bool once{false};

    if (this->addrIsRegistered()) {
        getBalances();

        if(!once) {
            this->getAddress();
            once = true;
        }
    }
}

void Libhai::waitout()
{
    emit endWait();
}

void Libhai::getAddress()
{
    const auto addr = address();
    QString address_base = QString(addr);
    QString adr_begin{}, adr_mid{"..."}, adr_end{};

    adr_begin = address_base.mid(0, 8);
    adr_end = address_base.mid(address_base.size() - 8, 8);

    emit addressUpdate(QVariant(adr_begin + adr_mid + adr_end));

    free(addr); // once done we need to free the pointer
}

void Libhai::getBalances()
{
    constexpr float decimals { 100000.f };
    auto balance_d = static_cast<float>(deros()) / decimals;
    auto balance_t = static_cast<float>(tokens()) / decimals;

    QString dero_f = QString::number(deros()).setNum(balance_d,'f',5);
    QString token_f = QString::number(tokens()).setNum(balance_t,'f',5);

    emit deroUpdate(QVariant(dero_f));
    emit tokenUpdate(QVariant(token_f));
}

bool Libhai::addrIsRegistered()
{
   return (isRegistered() > 0);
}

void Libhai::buy()
{
    m_wait.start();
    buyHai();
}

void Libhai::sell()
{
    m_wait.start();
    sellHai();
}

void Libhai::start()
{
    m_timer.start();
}

void Libhai::stop()
{
    m_timer.stop();
}
