package main

import (
	"C"
	"io/ioutil"
	"os"
	"time"

	"github.com/deroproject/derohe/config"
	"github.com/deroproject/derohe/cryptography/crypto"
	"github.com/deroproject/derohe/globals"
	"github.com/deroproject/derohe/rpc"
	"github.com/deroproject/derohe/transaction"
	"github.com/deroproject/derohe/walletapi"
)

const (
	//super secret password
	password = "secret"

	//scid of the SC
	HAI_SCID = "cb249f192df4d62d61f9dea5192da95b88a9649ce210bfd06d8c97a1628c23da"

	//a Random address
	addr_w1 = "deto1qxqzn8s6t2e3peexs9y6g55h5gteevz43082777wprxfm7f72p9xakce6g9ke"

	// Time
	blocktime = 18
	someSecs  = 3
)

var (
	// RPC params used in a SC_TX
	rpc_buy  = rpc.Argument{string("entrypoint"), rpc.DataString, string("Buy")}
	rpc_sell = rpc.Argument{string("entrypoint"), rpc.DataString, string("sell")}
)

type wallet struct {
	mem   *walletapi.Wallet_Memory
	addr  string
	dero  uint64
	token uint64
	reg   bool
	quit  chan bool
}

var wmem *wallet

func main() {}

func updates(w *wallet) {

	tick := time.NewTicker(time.Second * someSecs)
	defer tick.Stop()
for_loop:
	for {
		select {
		case <-tick.C:
			w.register()
			w.updateBalances()
		case <-w.quit:
			break for_loop
		default:
		}

	}

	globals.Logger.Infof("Quiting updates go routine properly.")
}

//export InitLib
func InitLib() {

	Init_common()

	wallet := Init_wallet()
	wmem = wallet

	wallet.connectToDaemon()

	go updates(wallet)

	globals.Logger.Infof("InitLib() initialized properly.")
}

func Init_common() {
	globals.Init_rlog()

	globals.Config = config.Testnet // Enforce Connect("") to connect on the good port
	walletapi.Initialize_LookupTable(1, 1<<17)

	arguments := make(map[string]interface{})
	arguments["--debug"] = true
	arguments["--testnet"] = true
	arguments["--rpc-server"] = false
	arguments["--offline"] = false
	arguments["--remote"] = false

	globals.Arguments = arguments

	globals.Initialize()
	globals.Logger.Out = ioutil.Discard // disable logrus

	globals.Logger.Infof("")
	globals.Logger.Out = os.Stdout // enable logrus
}

func Init_wallet() *wallet {
	var err error

	w, err := createWallet(password)
	if err != nil {
		globals.Logger.Warnf("error generating the m_wallet: %s", err)
		os.Exit(1)
	}

	return &wallet{
		mem:   w,
		addr:  w.GetAddress().String(),
		dero:  uint64(0),
		token: uint64(0),
		reg:   false,
		quit:  make(chan bool),
	}
}

func createWallet(password string) (wmem *walletapi.Wallet_Memory, err error) {
	wmem, err = walletapi.Create_Encrypted_Wallet_Random_Memory(password)
	return
}

func (w *wallet) register() {
	if !isRegistered() && !w.mem.IsRegistered() {
		reg_tx := w.mem.GetRegistrationTX()
		w.mem.SendTransaction(reg_tx)

		globals.Logger.Infof("Registering wallet...")

		wait_seconds(blocktime + someSecs)

		globals.Logger.Infof("wallet registered.")
	} else {
		w.reg = true
	}
}

func (w wallet) connectToDaemon() {
	w.mem.SetOnlineMode()
	go walletapi.Keep_Connectivity()

	wait_seconds(someSecs)
}

func (w *wallet) hai(r rpc.Argument, dero uint64, token uint64) (err error) {

	var sc_rpc = rpc.Arguments{}
	sc_rpc = append(sc_rpc, r)

	var p = rpc.SC_Invoke_Params{
		SC_ID:            string(HAI_SCID), // string    `json:"scid"`
		SC_RPC:           sc_rpc,           // Arguments `json:"sc_rpc"`
		SC_DERO_Deposit:  uint64(dero),     // uint64    `json:"sc_dero_deposit"`
		SC_TOKEN_Deposit: uint64(token),    // uint64    `json:"sc_token_deposit"`
	}

	var tp rpc.Transfer_Params
	tp.Transfers = append(tp.Transfers, rpc.Transfer{
		Destination: addr_w1,
		Amount:      0,
		Burn:        p.SC_DERO_Deposit,
	})

	if p.SC_TOKEN_Deposit >= 1 {
		scid := crypto.HashHexToHash(p.SC_ID)
		tp.Transfers = append(tp.Transfers, rpc.Transfer{SCID: scid, Amount: 0, Burn: p.SC_TOKEN_Deposit})
	}

	tp.SC_RPC = p.SC_RPC
	tp.SC_ID = p.SC_ID

	// Add SC_META_INFO
	p.SC_RPC = append(p.SC_RPC, rpc.Argument{rpc.SCACTION, rpc.DataUint64, uint64(rpc.SC_CALL)})
	p.SC_RPC = append(p.SC_RPC, rpc.Argument{rpc.SCID, rpc.DataHash, crypto.HashHexToHash(p.SC_ID)})

	// build SC_TX
	var tx *transaction.Transaction
	tx, err = w.mem.TransferPayload0(tp.Transfers, false, p.SC_RPC, false)
	if err != nil {
		return
	}
	_ = tx

	// Send SC_TX
	var uid string
	uid, err = w.mem.PoolTransfer(tp.Transfers, p.SC_RPC)
	if err != nil {
		globals.Logger.Warnf("PoolTransfer error: %s", err)
		return
	}
	_ = uid

	return
}
func wait_seconds(sec int64) {
	time.Sleep(time.Second * time.Duration(sec))
}

func (w *wallet) updateBalances() {
	if isRegistered() {
		scid := crypto.HashHexToHash(HAI_SCID)
		w.token, _ = w.mem.GetDecryptedBalanceAtTopoHeight(scid, -1, w.addr)
		w.dero, _ = w.mem.Get_Balance_Rescan()

		globals.Logger.Infof("Address: %s", w.addr)
		globals.Logger.Infof("Balance Dero (%d), token (%d)", w.dero, w.token)
	}
}

//export address
func address() *C.char {
	return C.CString(wmem.addr) // include stdlib.h and free the pointer once done
}

//export deros
func deros() uint64 {
	return wmem.dero
}

//export tokens
func tokens() uint64 {
	return wmem.token
}

//export isRegistered
func isRegistered() bool {
	return wmem.reg
}

//export finish
func finish() {
	wmem.quit <- true

	globals.Logger.Infof("finish() has been triggered.")
}

//export buyHai
func buyHai() {
	if wmem != nil && isRegistered() && wmem.dero >= uint64(500) {
		if err := wmem.hai(rpc_buy, 500, 0); err != nil {
			globals.Logger.Errorf("buyHai err: %s", err)
		}
		globals.Logger.Infof("buying...")
	}
}

//export sellHai
func sellHai() {
	if wmem != nil && isRegistered() && wmem.token >= uint64(3750) {
		if err := wmem.hai(rpc_sell, 0, 3750); err != nil {
			globals.Logger.Errorf("sellHai err: %s", err)
		}
		globals.Logger.Infof("selling...")
	}
}
