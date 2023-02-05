import React from "react"
import { useMoralis } from "react-moralis"
import { useEffect } from "react"
const ManualHeader = () => {
    const {
        enableWeb3,
        account,
        isWeb3Enabled,
        Moralis,
        deactivateWeb3,
        isWeb3EnableLoading,
    } = useMoralis()

    useEffect(() => {
        if (isWeb3Enabled) return
        if (typeof window != undefined) {
            if (window.localStorage.getItem("connected")) {
                enableWeb3()
            }
        }
        console.log(isWeb3Enabled)
    }, [isWeb3Enabled])

    useEffect(() => {
        Moralis.onAccountChanged((account) => {
            console.log(`Account has changed to ${account}`)
            if (account == null) {
                if (typeof window != undefined) {
                    deactivateWeb3()
                    window.localStorage.removeItem("connected")
                }
            }
        })
    }, [])
    return (
        <div>
            {account ? (
                <div>
                    Connected {account.slice(0, 6)}...{account.slice(account.length - 4)}
                </div>
            ) : (
                <button
                    onClick={async () => {
                        await enableWeb3()
                        if (typeof window != undefined) {
                            window.localStorage.setItem("connected", "injected")
                        }
                    }}
                    disabled={isWeb3EnableLoading}
                >
                    Connect
                </button>
            )}
        </div>
    )
}

export default ManualHeader
