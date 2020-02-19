import XCTest
@testable import XRPKit

final class XRPKitTests: XCTestCase {
    
    static var allTests = [
        ("testWS", testWS),
        ("testFundWallet", testFundWallet),
        ("testRandom", testRandom),
        ("testGenerateWalletFromSeed", testGenerateWalletFromSeed),
        ("testGenerateWalletFromMnemonicNoDerivationPath", testGenerateWalletFromMnemonicNoDerivationPath),
        ("testGenerateWalletFromMnemonicUsingDerivationPath", testGenerateWalletFromMnemonicUsingDerivationPath),
        ("testGenerateWalletFromMnemonicInvalidMnemonic", testGenerateWalletFromMnemonicInvalidMnemonic),
        ("testSecp256k1DerivationPath", testSecp256k1DerivationPath),
        ("testED25519DerivationPath", testED25519DerivationPath),
        ("testGetTxxs", testGetTxxs),
        ("testGetAccountInfo", testGetAccountInfo),
        ("testGetBalance", testGetBalance),
        ("testSerialization", testSerialization),
        ("readMe", ReadMe),
        ("testSendTx", testSendTx),
        ("testRippleEpoch", testRippleEpoch),
//        ("testEscrowCreateFinish", testEscrowCreateFinish),
//        ("testEscrowCreateCancel", testEscrowCreateCancel),
        ("testGetPendingEscrows", testGetPendingEscrows),
        ("testTransactionHistory", testTransactionHistory),
        ("testDisableMaster", testDisableMaster),
        ("testGetSignerList", testGetSignerList),
        ("testMultiSignEnableMaster", testMultiSignEnableMaster),
        ("testSignerListSet", testSignerListSet),
        ("testAccountID", testAccountID),
        ("testXAddress", testXAddress),
        ("testBip44", testBip44),
    ]
    
    func testBip44() {
        let mnemonic = "jar deer fox object wrap flush address birth immune plug spell solve reunion head mobile"
        let seed = Bip39Mnemonic.createSeed(mnemonic: mnemonic)
        let privateKey = PrivateKey(seed: seed, coin: .bitcoin)

        // BIP44 key derivation
        // m/44'
        let purpose = privateKey.derived(at: .hardened(44))

        // m/44'/0'
        let coinType = purpose.derived(at: .hardened(144))

        // m/44'/0'/0'
        let account = coinType.derived(at: .hardened(0))

        // m/44'/0'/0'/0
        let change = account.derived(at: .notHardened(0))

        // m/44'/0'/0'/0/0
        let firstPrivateKey = change.derived(at: .notHardened(0))
        print(firstPrivateKey.get())
        var finalMasterPrivateKey = Data(repeating: 0x00, count: 33)
        finalMasterPrivateKey.replaceSubrange(1...firstPrivateKey.raw.count, with: firstPrivateKey.raw)
        print(firstPrivateKey.publicKey.hexadecimal)
        let address = XRPSeedWallet.deriveAddress(publicKey: firstPrivateKey.publicKey.hexadecimal)
        print(address)
        XCTAssert(address == "rQ9f9FZkbeAVkJ9AYRfMYEaSboGwxHWuDd")
        
    }
    
    func testMultiSignEnableMaster() {
        let exp = expectation(description: "Loading stories")
        let wallet = try! XRPSeedWallet(seed: "ssJip5pqECDQuG5tdSehaKicmkN4d")
        let signer1 = try! XRPSeedWallet(seed: "shiZka2bSHQKw4CCcZNPFvvA2iAjR")
        let signer2 = try! XRPSeedWallet(seed: "snqFfd21bfALXF1PDj1ymdQcr3Vhu")
        let signer3 = try! XRPSeedWallet(seed: "sEdVWZmeUDgQdMEFKTK9kYVX71FKB7o")
        _ = try! XRPAccountSet(wallet: wallet, clear: .asfDisableMaster)
            .autofill()
            .map({ (tx) in
                let _tx = try! tx
                .addMultiSignSignature(wallet: signer3)
                .addMultiSignSignature(wallet: signer1)
                .addMultiSignSignature(wallet: signer2)
                .submit()
                .map { (dict) in
                        print(dict)
                        exp.fulfill()
                }
            })
            
        waitForExpectations(timeout: 10)
    }
    
    func testDisableMaster() {
        let exp = expectation(description: "Loading stories")
        let wallet = try! XRPSeedWallet(seed: "ssJip5pqECDQuG5tdSehaKicmkN4d")
        XRPAccountSet(wallet: wallet, set: .asfDisableMaster)
            .send()
            .map { (dict) in
            print(dict)
            exp.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testGetSignerList() {
        let exp = expectation(description: "Loading stories")
        let wallet = try! XRPSeedWallet(seed: "ssJip5pqECDQuG5tdSehaKicmkN4d")
        XRPLedger.getSignerList(address: wallet.address).map { (dict) in
            print(dict)
            exp.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSignerListSet() {
        let exp = expectation(description: "Loading stories")
        
        let wallet = try! XRPSeedWallet(seed: "ssJip5pqECDQuG5tdSehaKicmkN4d")
        let signer1 = try! XRPSeedWallet(seed: "shiZka2bSHQKw4CCcZNPFvvA2iAjR")
        let signer2 = try! XRPSeedWallet(seed: "snqFfd21bfALXF1PDj1ymdQcr3Vhu")
        let signer3 = try! XRPSeedWallet(seed: "sEdVWZmeUDgQdMEFKTK9kYVX71FKB7o")
        let signers = [signer1, signer2, signer3].map { (wallet) -> XRPSignerEntry in
            return XRPSignerEntry(Account: wallet.address, SignerWeight: 1)
        }
        
        _ = XRPSignerListSet(wallet: wallet, signerQuorum: 3, signerEntries: signers).send().map { (dict) in
            print(dict)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }

    func testWS() {
        // create the expectation
        let exp = expectation(description: "Loading stories")

        // call my asynchronous method
        let wst = WebSocketTester { (info) in
            print(info)
            exp.fulfill()
        }
        XRPLedger.ws.delegate = wst
        XRPLedger.ws.connect(host: XRPLHost.xrpl_ws_Testnet.rawValue)
        let parameters: [String: Any] = [
            "id" : "test",
            "method" : "fee"
        ]
        let data = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        XRPLedger.ws.send(data: data)

        // wait three seconds for all outstanding expectations to be fulfilled
        waitForExpectations(timeout: 5)
    }
    
    func testRippleEpoch() {
        let dateString = "2017-11-13T00:00:00.000Z"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = formatter.date(from: dateString)!
        XCTAssert(date.timeIntervalSinceRippleEpoch == UInt64(563846400))
    }
    
//    func testEscrowCreateFinish() {
//        let exp = expectation(description: "Testing \(#function)")
//
//        let wallet = try! XRPSeedWallet(seed: "sEdVLSxBzx6Xi9XTqYj6a88epDSETKR")
//        let amount = try! XRPAmount(drops: 1100000)
//        let address = try! XRPAddress(rAddress: "rUQyLm1pnvFPcYgAFFVu7MvBgEYqWEfrjp")
//        let create = XRPEscrowCreate(from: wallet, to: address, amount: amount, finishAfter: Date().addingTimeInterval(TimeInterval(5)), cancelAfter: nil)
//        _ = create.send().map { (dict) in
//            DispatchQueue.main.asyncAfter(deadline: .now()+10) {
//                let txJSON = dict["tx_json"] as! NSDictionary
//                let sequence = txJSON["Sequence"] as! UInt32
//                print(txJSON)
//                let finish = XRPEscrowFinish(using: wallet, owner: wallet.address, offerSequence: sequence)
//                _ = finish.send().map { (dict) in
//                    print(dict)
//                    exp.fulfill()
//                }
//            }
//        }
//        waitForExpectations(timeout: 30)
//    }
//
//    func testEscrowCreateCancel() {
//        let exp = expectation(description: "Testing \(#function)")
//
//        let wallet = try! XRPSeedWallet(seed: "sEdVLSxBzx6Xi9XTqYj6a88epDSETKR")
//        let amount = try! XRPAmount(drops: 1100000)
//        let address = try! XRPAddress(rAddress: "rUQyLm1pnvFPcYgAFFVu7MvBgEYqWEfrjp")
//        let create = XRPEscrowCreate(from: wallet, to: address, amount: amount, finishAfter: Date().addingTimeInterval(TimeInterval(4)), cancelAfter: Date().addingTimeInterval(TimeInterval(5)))
//        _ = create.send().map { (dict) in
//            DispatchQueue.main.asyncAfter(deadline: .now()+10) {
//                let txJSON = dict["tx_json"] as! NSDictionary
//                let sequence = txJSON["Sequence"] as! UInt32
//                print(txJSON)
//                let finish = XRPEscrowCancel(using: wallet, owner: wallet.address, offerSequence: sequence)
//                _ = finish.send().map { (dict) in
//                    print(dict)
//                    exp.fulfill()
//                }
//            }
//        }
//        waitForExpectations(timeout: 30)
//    }
    
    func testGetPendingEscrows() {
        let exp = expectation(description: "Testing \(#function)")

        let wallet = try! XRPSeedWallet(seed: "sEdVLSxBzx6Xi9XTqYj6a88epDSETKR")
        _ = XRPLedger.getPendingEscrows(address: wallet.address).map { (dict) in
            print(dict)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testTransactionHistory() {
        let exp = expectation(description: "Testing \(#function)")
        
        let wallet = try! XRPSeedWallet(seed: "sEdVLSxBzx6Xi9XTqYj6a88epDSETKR")
        _ = XRPLedger.getTxs(account: wallet.address).map { (txs) in
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testRandom() {
        let random = try! URandom()
        let bytes = try! random.bytes(count: 16)
        print(Data(bytes).toHexString())
        let wallet = XRPSeedWallet()
        print(wallet)
    }
    
    func testGenerateWalletFromInvalidSeed() {
        do {
            let _ = try XRPSeedWallet(seed: "xrp")
             XCTFail("Should not generate wallet")
        } catch {
            XCTAssertTrue(
                error is SeedError,
                "Unexpected error type: \(type(of: error))"
            )
        }
    }
    
    func testGenerateWalletFromSeed() {
        do {
            let wallet = try XRPSeedWallet(seed: "snYP7oArxKepd3GPDcrjMsJYiJeJB")
            XCTAssertNotNil(wallet)
            XCTAssertEqual(wallet.publicKey, "02fd0e8479ce8182abd35157bb0fa17a469af27dcb12b5dded697c61809116a33b")
            XCTAssertEqual(wallet.privateKey, "0027690792130fc12883e83ae85946b018b3bede6eedcda3452787a94fc0a17438")
            XCTAssertEqual(wallet.address, "rByLcEZ7iwTBAK8FfjtpFuT7fCzt4kF4r2")
        } catch {
            XCTFail("Could not generate wallet")
        }
    }
    
    func testGenerateWalletFromMnemonicNoDerivationPath() {
        let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let wallet = try! XRPMnemonicWallet(mnemonic: mnemonic)

        XCTAssertEqual(wallet.publicKey, "031D68BC1A142E6766B2BDFB006CCFE135EF2E0E2E94ABB5CF5C9AB6104776FBAE")
        XCTAssertEqual(wallet.privateKey, "0090802A50AA84EFB6CDB225F17C27616EA94048C179142FECF03F4712A07EA7A4")
        XCTAssertEqual(XRPAddress.encodeXAddress(rAddress: wallet.address), "XVMFQQBMhdouRqhPMuawgBMN1AVFTofPAdRsXG5RkPtUPNQ")
    }
    
    func testGenerateWalletFromMnemonicUsingDerivationPath() {
        let mnemonic = "recycle rocket rain scout rule loud pudding they panther advance acquire junk news trumpet bitter"
        let wallet = try! XRPMnemonicWallet(mnemonic: mnemonic, account: 76, change: 1, addressIndex: 4)

        XCTAssertEqual(wallet.publicKey, "034ac49ef8112bb1e8fe9e4610aa24eb48bf6d8d5ddef36adc5b460829aedc61c0".uppercased())
        XCTAssertEqual(wallet.privateKey, "00" + "20adf2745186a58b30172626ed761042904610f42326897aca0a98840036b1a2".uppercased())
        XCTAssertEqual(wallet.address, "rf5UyN1ETEzfQKkD5mdcReQEd2gTk46wiz")
    }
    
    func testGenerateWalletFromMnemonicInvalidMnemonic() {
        do {
            let mnemonic = "xrp xrp xrp xrp xrp xrp xrp xrp xrp xrp xrp xrp"
            let _ = try XRPMnemonicWallet(mnemonic: mnemonic)
        } catch {
            XCTAssertTrue(
                error is SeedError,
                "Unexpected error type: \(type(of: error))"
            )
        }
    }
    
    func testSecp256k1DerivationPath() {
        let tests = [
            [
                "00fc04a8e1c707ba9568786ef59bfbbd81c177079a056e15ed479d86c1af8b2d70",
                "037519acdf131ccd412cf8d8b7b09a38e8ceeb62cbf40df797eb8c2e3ed3a2e2e0",
                "snqFfd21bfALXF1PDj1ymdQcr3Vhu",
                "r4gTV9iKgrW4VRjUAFZ6zZgVMDHLW5MCGX"
            ],
            [
                "00cdb06b49b44cb5958a89f6af1303ebeff22344567c37329c28d21834ea72d505",
                "03ee379cfa4fbfc4934750d0f1274c97e38a9269bf8ceac72ea24bbab12cd4ec2f",
                "shmHbzopVRdMe5YAnMb7afMsGA1ps",
                "rKfi51fkW5RCPrjfiXNsPT7Fj6ouKeFgS2"
            ],
            [
                "00d50aed2ec121f41c55c31887e0b74622a8a5babd8cb5cfdffa9f759bb2fe4d72",
                "02a09d126a090fa30ec9171466006d113a391c25b044b5502c89f13610208d3be3",
                "ss5xFsAN7g581aomQX7spuikXvEZV",
                "rQsujmjCUqX2UkgSnjErN7LLK7YovqMq1M"
            ],
            [
                "00bb5ee44acb866914453e9ba9ecc2aa53e2ed703053d2ace22bf689e0c326a005",
                "0309b16830b146e6d6f90b68fdb1363ac436c298ac0ba675478c40a6806e35f5d3",
                "shWtjvRfo5ZrENf3g6ScUWVSZiwe5",
                "rLMk48nzBxUmHkZkDMctZBnwuUzuKyAGz9"
            ],
            [
                "001944b8944a3dcf3019d26302328a5e39db16dd03755569b0d8a8c029e2fdb986",
                "021be5e68fc20cf53f54b77acff66d63f57fc5b85986b3d278ba55758ff18b7655",
                "ss6wZGXGVKJQmCa8XyW7oPPoZAuGC",
                "rK8xxM7q5mM8y43mAJuFno7swh2w7X3Art"
            ],
            [
                "00bdbf4e3adec96b7dafd8bda1af1f39a3e0fb6d80562fb5f3f493d0890526b930",
                "02360fccec17d64b028f5ad8c7574d84fa9962ac0860f8f39784924670931b9598",
                "sn8fLfZc1u3KQyHZiM4XvAV7gb5zG",
                "rKtJbhdsWNy9NjMrViuiKqcwm8n9V7btH3"
            ],
            [
                "00e81033c42d6821827ff63ff2afada9291b4d7d5e19112fe5f728759ab7290caa",
                "02593f9492e8ea193eb727fb9a830670506c550b94888b62c89f9bdc5727ede703",
                "snhx4wD1WmY3ArCi5GJrmCWu3uLaR",
                "rppUJh4YMyEdsTdUYdJct82BzsyrnpRkU2"
            ],
            [
                "0087b9d1b486810d2b4ce24679a270adc5df04817e62a885af447c8f21788db729",
                "0313ce0e1f0cb78beb89a597189c66a363ef95f5bb176465e831ff5c85eafc2200",
                "snSnWjQqnhJXjyy6BYWURMyPAwRmi",
                "rhbmDriGdQexcmiDqHXH36uE3v5Kb4UeBa"
            ],
            [
                "00e4ba6e0a26434f997507a820e2931d01c8d7be5dd520da000c575eac564ed8f3",
                "034dcfc9681dd6b9e3cd837e50810bd76fb24af6b5d1a2eb4ea1994873307e7b03",
                "sncpfnA8Hys5KtTQhEXpvej34wjHj",
                "rnq1Rg1fwgUPisaMvpjbz3fd7wCnDM4hey"
            ],
            [
                "0092fb913245792c9d0032d18afdb20bd36763b5d777e26aa1515b3ce39cee488f",
                "03092fe4837f508c41b98197ab04499a356ee5d193a0fb825e2fb7a8f0e85379ab",
                "ssBcBm3H44AJgMhguu5g6HWYhiHTZ",
                "rCYAs5jCspt3wb5akULR7Zx6Y912G1obt"
            ],
            [
                "0053d3ce49ec0f4cee787519ebcee6cec50157012c9940082d938d7305e3ea1eb5",
                "02bca00063eaa8304f3069c3887dc8e154a9ad7f3ad5c7dcd39ca38ba28f58dea9",
                "spmDyK6dJ1oQo1xbhSvhuBtBfPjBt",
                "rwTtwjBtc3k3zhezi9wprsz6mfgxhoRYn9"
            ],
            [
                "00f6bc9f5a0e086907a6731389dc2b0fa96da84a660e3cd867a5967f7736de124b",
                "02c42a807e2899d0a3f450b87033a54c11661ebe30bfe359292130e18739f5bd2c",
                "ssV8vurkfiv3myD8jZ6xPBoodsgX7",
                "rJqwaFVZoXcWL4wVV9kGxZqGfYTaqeKoYf"
            ],
            [
                "00dc7fd67193f515bee7290c02f2ba94e4c2345525579ce9c654ff0f4f32ec9249",
                "03648942674421a297111a2e836ce6ccd800a9d7767c9c5f5221dad9710520ebd1",
                "sp8uRe9nMriho3SWpSZeUV3r43SeQ",
                "r4uycvyuGhPz9kMz5weDHgoBYQK8sAGvXW"
            ],
            [
                "0087ab103afefe43981b3ea60df795e61f45c494c7f36078a2a4056334f40f9825",
                "023baf690192b164c6dbfb248a9357e6bdf39ca85f9f709c1c00c6044312d2db79",
                "ssq4XdDSEr5kXTxS6ou849iwYG8Eh",
                "rntu6JRKC12Nyt9sE8iATgHzKESyZoVYqe"
            ],
            [
                "00b86ac7969d349944143774008a3b2171e133d01beed43f33569157c17a556c34",
                "02e948359aacb5b2675d957b151290f561badedd065c9ce8e32a23c0779b39ebf5",
                "snCjTj1boumKg9d3rZK8qaWNjnBzy",
                "rQDRHPJfPDCkE65jKBtgtaSY3CpdDjkNZC"
            ],
            [
                "00aff3f16f5c72b0a9650f994cd1aede093c2414da82f9d29a1cb16528e3ddb4a4",
                "02b71c0215b676d69209b7980d90d9a8f48db887784a65e4ffd38be753a98b6cb0",
                "snhDK6Neh8yeXX96McRU3rGGRQrbo",
                "rH77iYSHdrm6SaD15Q6xHJMhsfFZURyhzj"
            ],
            [
                "0072cfd530266a468c997ef2d9a40a898c02859449db93ec78c4ae1fb28705438c",
                "02229054dd28e20f6e25f6771797a3cd0de3d5fd55dfc4de1a4709c48683cdc90d",
                "sasv5H2DRjEkWJDAsBYdBk48nLa1e",
                "rfRLtECrXXZbWPTY1zgyLnEnzSbTBgUYYy"
            ],
            [
                "0086dfb98b438427d7be932cfcd205a457b62270ead48f0662b7c1dcc15a330bb8",
                "037aa922fb49b97c8cca04d57a64be599ddceedcdd4b99ceaafa2c78a1eca56fce",
                "ssiZsmPx5fhpNimWzXGy111tyXTTQ",
                "ravfrPYRRPbHGPVAJqdw8h57bqS4jawhmt"
            ],
            [
                "002ed54b43f27e922014c1f12af59ca7f1c44910ce4e3c603e05aa221f86a95953",
                "032db55994e46fd24b64f9688272faedd09b8af660eec47f7c0fc4a07b646edc5d",
                "sn3qcErHhys9Z7EzgkRRkYTpsroYb",
                "rLtCkxyQJMGoNMHmWdY7gg1Zh3tVAYePSK"
            ],
            [
                "000d5f0f8386268563477093dddbe240cf29b2bd149cde7a8be65387d629a114ed",
                "03b06acd6bf9f733ed12949863c6dfdafebb9c5771658d23046656aeb590b4fee8",
                "shwtWWu2q1UUuF8waXe3LNPaUJ3Wc",
                "rKXXbQeknkC5ZdxA45dXuCVgUpJpHT86US"
            ],
            [
                "00bcd722763f316bc4554aaccaa61e8e060304020adbb578901c9a47bd03e64956",
                "029cb31945f42e0db0a887ab3747a14b789c4108d38232311bd6e8a9c1b4529c03",
                "sniQ7AheddnEu46c48tryizzgDzyi",
                "rUiYmVzXgVurPea56pgdBPCJrzGFxECzcr"
            ]
        ]
        
        for test in tests {
            let privateKey = test[0]
            let publicKey = test[1]
            let seed = test[2]
            let address = test[3]
            let wallet = try! XRPSeedWallet(seed: seed)
            XCTAssertEqual(wallet.privateKey, privateKey)
            XCTAssertEqual(wallet.publicKey, publicKey)
            XCTAssertEqual(wallet.address, address)
            XCTAssertEqual(wallet.seed, seed)
            XCTAssertEqual(XRPSeedWallet.getSeedTypeFrom(publicKey: wallet.publicKey), .secp256k1)
        }
        
    }
    
    func testED25519DerivationPath() {
        let dict = [
            "sEdVWZmeUDgQdMEFKTK9kYVX71FKB7o" : "r34XnDB2zS11NZ1wKJzpU1mjWExGVugTaQ",
            "sEd7zJoVnqg1FxB9EuaHC1AB5UPfHWz" : "rDw51qRrBEeMw7Na1Nh79LN7HYZDo7nZFE",
            //        "sEdSxVntbihdLyabbfttMCqsaaucVR9" : "rwiyBDfAYegXZyaQcN2L1vAbKRYn2wNFMq",
            //        "sEdSVwJjEXTYCztqDK4JD9WByH3otDX" : "rQJ4hZzNGkLQhLtKPCmu1ywEw1ai2vgUJN",
            //        "sEdV3jXjKuUoQTSr1Rb4yw8Kyn9r46U" : "rERRw2Pxbau4tevE61V5vZUwD7Rus5Y6vW",
            //        "sEdVeUZjuYT47Uy51FQCnzivsuWyiwB" : "rszewT5gRjUgWNEmnfMjvVYzJCkhvWY32i",
            //        "sEd7MHTewdw4tFYeS7rk7XT4qHiA9jH" : "rBB2rvnf4ztwjgNhinFXQJ91nAZjkFgR3p",
            //        "sEd7A5jFBSdWbNeKGriQvLr1thBScJh" : "rLAXz8Nz7aDivz7PwThsLFqaKrizepNCdA",
            //        "sEdVPU9M2uyzVNT4Yb5Dn4tUtYjbFAw" : "rHbHRFPCxD5fnn98TBzsQHJ7SsRq7eHkRj",
            //        "sEdVfF2zhAmS8gfMYzJ4yWBMeR4BZKc" : "r9PsneKHcAE7kUfiTixomM5Mnwi28tCc7h",
            //        "sEdTjRtcsQkwthDXUSLi9DHNyJcR8GW" : "rM4soF4XS3wZrmLurvE6ZmudG16Lk5Dur5",
            //        "sEdVNKeu1Lhpfh7Nf6tRDbxnmMyZ4Dv" : "r4ZwJxq6FDtWjapDtCGhjG6mtNm1nWdJcD",
            //        "sEd7bK4gf5BHJ1WbaEWx8pKMA9MLHpC" : "rD6tnn51m4o1uXeEK9CFrZ3HR7DcFhiYnp",
            //        "sEd7jCh3ppnQMsLdGcZ6TZayZaHhBLg" : "rTcBkiRQ1EfFQ4FCCwqXNHpn1yUTAACkj",
            //        "sEdTFJezurQwSJAbkLygj2gQXBut2wh" : "rnXaMacNbRwcJddbbPbqdcpSUQcfzFmrR8",
            //        "sEdSWajfQAAWFuDvVZF3AiGucReByLt" : "rBJtow6V3GTdsWMamrxetRDwWs6wwTxcKa",
        ]
        
        for (secret, address) in dict {
            let wallet = try! XRPSeedWallet(seed: secret)
            XCTAssertEqual(wallet.address, address)
            XCTAssertEqual(wallet.seed, secret)
            XCTAssertEqual(XRPSeedWallet.getSeedTypeFrom(publicKey: wallet.publicKey), .ed25519)
        }
    }
    
    func testGetTxxs() {
        // create the expectation
        let exp = expectation(description: "Loading stories")
        
        // call my asynchronous method
        let wallet = try! XRPSeedWallet(seed: "ssExhwra2PtqmPWYQvDyHTkycsdGn")
        _ = XRPLedger.getTxs(account: wallet.address).map { (transactions) in
            print(transactions)
            exp.fulfill()
        }
        
        // wait three seconds for all outstanding expectations to be fulfilled
        waitForExpectations(timeout: 3)
    }
    
    func testGetAccountInfo() {
        // create the expectation
        let exp = expectation(description: "Loading stories")
        
        // call my asynchronous method
        let wallet = try! XRPSeedWallet(seed: "sEdVLSxBzx6Xi9XTqYj6a88epDSETKR")
        _ = XRPLedger.getAccountInfo(account: wallet.address).map { (info) in
            print(info)
            exp.fulfill()
        }
        
        // wait three seconds for all outstanding expectations to be fulfilled
        waitForExpectations(timeout: 3)
    }
    
    func testSendTx() {
        // create the expectation
        let exp = expectation(description: "Loading stories")
        
        // call my asynchronous method
        let wallet = try! XRPSeedWallet(seed: "sEdVLSxBzx6Xi9XTqYj6a88epDSETKR")
        print(wallet.address)
        print(wallet.seed)
        print(wallet.privateKey)
        print(wallet.publicKey)
        let amount = try! XRPAmount(drops: 1000000)
        let address = try! XRPAddress(rAddress: "rUQyLm1pnvFPcYgAFFVu7MvBgEYqWEfrjp", tag: 43)
        _ = XRPPayment(from: wallet, to: address, amount: amount, sourceTag: 67).send().map({ (dict) in
            print(dict)
            exp.fulfill()
        })
        
        // wait three seconds for all outstanding expectations to be fulfilled
        waitForExpectations(timeout: 10)
    }
    
    func testAccountID() {
        let wallet = XRPSeedWallet()
        let a = Data(wallet.accountID).hexadecimal.uppercased()
        let b = Data(XRPSeedWallet.accountID(for: wallet.address)).hexadecimal.uppercased()
        XCTAssert(a == b)
    }
    
    func testXAddress() {
        let mainNetTests = [
        [
        nil,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtV5fdx1mHp98tDMoQXb",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A000000000000000000",
        ],[
        0,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtV8AqEL4xcZj5whKbmc",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A010000000000000000",
        ],[
        1,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtV8xvjGQTYPiAx6gwDC",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A010100000000000000",
        ],[
        2,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtV8zpDURx7DzBCkrQE7",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A010200000000000000",
        ],[
        32,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtVoYiC9UvKfjKar4LJe",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A012000000000000000",
        ],[
        276,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtVoKj3MnFGMXEFMnvJV",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A011401000000000000",
        ],[
        65591,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtVozpjdhPQVdt3ghaWw",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A013700010000000000",
        ],[
        16781933,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtVqrDUk2vDpkTjPsY73",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A016D12000100000000",
        ],[
        4294967294,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A01FEFFFFFF00000000",
        ],[
        4294967295,
        "XVLhHMPHU98es4dbozjVtdWzVrDjtV18pX8yuPT7y4xaEHi",
        "A066C988C712815CC37AF71472B7CBBBD4E2A0A01FFFFFFFF00000000",
        ]
        ]
        let rootAccount = "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf"
        for test in mainNetTests {
            let _tag = test[0] as? Int
            let tag = _tag == nil ? nil : UInt32(String(_tag!))
            let x_address = XRPAddress.encodeXAddress(rAddress: rootAccount, tag: tag, test: false)
            XCTAssert(test[1] as! String == x_address)
            
            let xrpAddress = try! XRPAddress.decodeXAddress(xAddress: x_address)
            XCTAssert(xrpAddress.tag == tag && xrpAddress.rAddress == rootAccount)
        }
        XCTAssert(XRPAddress.encodeXAddress(rAddress: rootAccount, tag: 4294967295, test: false) == "XVLhHMPHU98es4dbozjVtdWzVrDjtV18pX8yuPT7y4xaEHi")
        XCTAssert(XRPAddress.encodeXAddress(rAddress: rootAccount, tag: 4294967294, test: false) == "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u")
        XCTAssert(XRPAddress.encodeXAddress(rAddress: "rPEPPER7kfTD9w2To4CQk6UCfuHM9c6GDY", tag: 12345, test: false) == "XV5sbjUmgPpvXv4ixFWZ5ptAYZ6PD28Sq49uo34VyjnmK5H")
        let address = try! XRPAddress.decodeXAddress(xAddress: "XV5sbjUmgPpvXv4ixFWZ5ptAYZ6PD28Sq49uo34VyjnmK5H")
        XCTAssert(address.rAddress == "rPEPPER7kfTD9w2To4CQk6UCfuHM9c6GDY" && address.tag == 12345)
        
    }
    
    func testGetBalance() {
        // create the expectation
        let exp = expectation(description: "Loading stories")
        
        // call my asynchronous method
        let wallet = try! XRPSeedWallet(seed: "ssExhwra2PtqmPWYQvDyHTkycsdGn")
        _ = XRPLedger.getBalance(address: wallet.address).map { (result) in
            print(result)
            exp.fulfill()
        }
        
        // wait three seconds for all outstanding expectations to be fulfilled
        waitForExpectations(timeout: 3)
    }
    
    func testSerialization() {
        
        let tx1 = """
        {
        "Account": "rMBzp8CgpE441cp5PVyA9rpVV7oT8hP3ys",
        "Expiration": 595640108,
        "Fee": "10",
        "Flags": 524288,
        "OfferSequence": 1752791,
        "Sequence": 1752792,
        "SigningPubKey": "03EE83BB432547885C219634A1BC407A9DB0474145D69737D09CCDC63E1DEE7FE3",
        "TakerGets": "15000000000",
        "TakerPays": {
        "currency": "USD",
        "issuer": "rvYAfWj5gh67oV6fW32ZzP3Aw4Eubs59B",
        "value": "7072.8"
        },
        "TransactionType": "OfferCreate",
        "TxnSignature": "30440220143759437C04F7B61F012563AFE90D8DAFC46E86035E1D965A9CED282C97D4CE02204CFD241E86F17E011298FC1A39B63386C74306A5DE047E213B0F29EFA4571C2C",
        "hash": "73734B611DDA23D3F5F62E20A173B78AB8406AC5015094DA53F53D39B9EDB06C"
        }
        """
        let tx2 = """
        {
        "TransactionType": "EscrowFinish",
        "Flags": 2147483648,
        "Sequence": 1,
        "OfferSequence": 11,
        "Fee": "10101",
        "SigningPubKey": "0268D79CD579D077750740FA18A2370B7C2018B2714ECE70BA65C38D223E79BC9C",
        "TxnSignature": "3045022100F06FB54049D6D50142E5CF2E2AC21946AF305A13E2A2D4BA881B36484DD01A540220311557EC8BEF536D729605A4CB4D4DC51B1E37C06C93434DD5B7651E1E2E28BF",
        "Account": "r3Y6vCE8XqfZmYBRngy22uFYkmz3y9eCRA",
        "Owner": "r9NpyVfLfUG8hatuCCHKzosyDtKnBdsEN3",
        "Memos": [
        {
        "Memo": {
        "MemoData": "04C4D46544659A2D58525043686174"
        }
        }
        ]
        }
        """
        let tx3 = """
        {
        "Account": "rweYz56rfmQ98cAdRaeTxQS9wVMGnrdsFp",
        "Amount": "10000000",
        "Destination": "rweYz56rfmQ98cAdRaeTxQS9wVMGnrdsFp",
        "Fee": "12",
        "Flags": 0,
        "LastLedgerSequence": 9902014,
        "Memos": [
        {
        "Memo": {
        "MemoData": "7274312E312E31",
        "MemoType": "636C69656E74"
        }
        }
        ],
        "Paths": [
        [
        {
        "account": "rPDXxSZcuVL3ZWoyU82bcde3zwvmShkRyF",
        "type": 1,
        "type_hex": "0000000000000001"
        },
        {
        "currency": "XRP",
        "type": 16,
        "type_hex": "0000000000000010"
        }
        ],
        [
        {
        "account": "rf1BiGeXwwQoi8Z2ueFYTEXSwuJYfV2Jpn",
        "type": 1,
        "type_hex": "0000000000000001"
        },
        {
        "account": "rMwjYedjc7qqtKYVLiAccJSmCwih4LnE2q",
        "type": 1,
        "type_hex": "0000000000000001"
        },
        {
        "currency": "XRP",
        "type": 16,
        "type_hex": "0000000000000010"
        }
        ]
        ],
        "SendMax": {
        "currency": "USD",
        "issuer": "rweYz56rfmQ98cAdRaeTxQS9wVMGnrdsFp",
        "value": "0.6275558355"
        },
        "Sequence": 842,
        "SigningPubKey": "0379F17CFA0FFD7518181594BE69FE9A10471D6DE1F4055C6D2746AFD6CF89889E",
        "TransactionType": "Payment",
        "TxnSignature": "3045022100D55ED1953F860ADC1BC5CD993ABB927F48156ACA31C64737865F4F4FF6D015A80220630704D2BD09C8E99F26090C25F11B28F5D96A1350454402C2CED92B39FFDBAF",
        "hash": "B521424226FC100A2A802FE20476A5F8426FD3F720176DC5CCCE0D75738CC208"
        }
        """
        
        let txs = [
            tx1 : "120007220008000024001ABED82A2380BF2C2019001ABED764D55920AC9391400000000000000000000000000055534400000000000A20B3C85F482532A9578DBB3950B85CA06594D165400000037E11D60068400000000000000A732103EE83BB432547885C219634A1BC407A9DB0474145D69737D09CCDC63E1DEE7FE3744630440220143759437C04F7B61F012563AFE90D8DAFC46E86035E1D965A9CED282C97D4CE02204CFD241E86F17E011298FC1A39B63386C74306A5DE047E213B0F29EFA4571C2C8114DD76483FACDEE26E60D8A586BB58D09F27045C46",
            tx2 : "1200022280000000240000000120190000000B68400000000000277573210268D79CD579D077750740FA18A2370B7C2018B2714ECE70BA65C38D223E79BC9C74473045022100F06FB54049D6D50142E5CF2E2AC21946AF305A13E2A2D4BA881B36484DD01A540220311557EC8BEF536D729605A4CB4D4DC51B1E37C06C93434DD5B7651E1E2E28BF811452C7F01AD13B3CA9C1D133FA8F3482D2EF08FA7D82145A380FBD236B6A1CD14B939AD21101E5B6B6FFA2F9EA7D0F04C4D46544659A2D58525043686174E1F1",
            tx3 : "1200002200000000240000034A201B009717BE61400000000098968068400000000000000C69D4564B964A845AC0000000000000000000000000555344000000000069D33B18D53385F8A3185516C2EDA5DEDB8AC5C673210379F17CFA0FFD7518181594BE69FE9A10471D6DE1F4055C6D2746AFD6CF89889E74473045022100D55ED1953F860ADC1BC5CD993ABB927F48156ACA31C64737865F4F4FF6D015A80220630704D2BD09C8E99F26090C25F11B28F5D96A1350454402C2CED92B39FFDBAF811469D33B18D53385F8A3185516C2EDA5DEDB8AC5C6831469D33B18D53385F8A3185516C2EDA5DEDB8AC5C6F9EA7C06636C69656E747D077274312E312E31E1F1011201F3B1997562FD742B54D4EBDEA1D6AEA3D4906B8F100000000000000000000000000000000000000000FF014B4E9C06F24296074F7BC48F92A97916C6DC5EA901DD39C650A96EDA48334E70CC4A85B8B2E8502CD310000000000000000000000000000000000000000000"
        ]
        
        for (tx, result) in txs {let jsonResult = try! JSONSerialization.jsonObject(with: tx.data(using: .utf8)!, options: .mutableLeaves)
            if let jsonResult = jsonResult as? [String:AnyObject] {
                let blob = Serializer().serializeTx(tx: jsonResult, forSigning: false)
                let hex = blob.toHexString().uppercased()
                XCTAssertEqual(hex, result.uppercased())
            }
            
        }
        
    }
    
    func testFundWallet() {
        let ED_wallet = try! XRPSeedWallet(seed: "sEdVLSxBzx6Xi9XTqYj6a88epDSETKR")
        print(ED_wallet.address)
        print(ED_wallet.seed)
        print(ED_wallet.privateKey)
        print(ED_wallet.publicKey)
        // create the expectation
        let exp = expectation(description: "Loading stories")
        
        // call my asynchronous method
        let wallet = try! XRPSeedWallet(seed: "ssA9fFYomuCurjdHQgxdLJjz1nhNn")
        let amount = try! XRPAmount(drops: 500000000)
        let address = try! XRPAddress(rAddress: ED_wallet.address)
        let _ = XRPPayment(from: wallet, to: address, amount: amount).send().map { (result) in
            print(result)
            exp.fulfill()
        }
        
        // wait three seconds for all outstanding expectations to be fulfilled
        waitForExpectations(timeout: 3)
    }
    
    
    // make sure this compiles (dont run)
    func ReadMe() {
        
        
        // ================================================================================================
        // Create a new wallet
        // ================================================================================================
        // create a completely new, randomly generated wallet
        let wallet = XRPSeedWallet() // defaults to secp256k1
        let wallet2 = XRPSeedWallet(type: .secp256k1)
        let wallet3 = XRPSeedWallet(type: .ed25519)
        
        // ignore
        _ = wallet2.address + wallet3.address
        
        
        
        // ================================================================================================
        // Derive wallet from a seed
        // ================================================================================================
        // generate a wallet from an existing seed
        let walletFromSeed = try! XRPSeedWallet(seed: "snsTnz4Wj8vFnWirNbp7tnhZyCqx9")
        
        // ignore
        _ = walletFromSeed
        
        // ================================================================================================
        // Derive wallet from a mnemonic
        // ================================================================================================

        let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let walletFromMnemonic = try! XRPMnemonicWallet(mnemonic: mnemonic)
        
        // ignore
        _ = walletFromMnemonic
        
        
        // ================================================================================================
        // Wallet properties
        // ================================================================================================
        print(wallet.address) // rJk1prBA4hzuK21VDK2vK2ep2PKGuFGnUD
        print(wallet.seed) // snsTnz4Wj8vFnWirNbp7tnhZyCqx9
        print(wallet.publicKey) // 02514FA7EF3E9F49C5D4C487330CC8882C0B4381BEC7AC61F1C1A81D5A62F1D3CF
        print(wallet.privateKey) // 003FC03417669696AB4A406B494E6426092FD9A42C153E169A2B469316EA4E96B7
        
        
        
        // ================================================================================================
        // Validation
        // ================================================================================================
        // Address
        let btc = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
        let xrp = "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK"
        
        _ = XRPSeedWallet.validate(address: btc) // returns false
        _ = XRPSeedWallet.validate(address: xrp) // returns true
        
        // Seed
        let seed = "shrKftFK3ZkMPkq4xe5wGB8HaNSLf"
        
        _ = XRPSeedWallet.validate(seed: xrp) // returns false
        _ = XRPSeedWallet.validate(seed: seed) // returns true
        
        
        
        // ================================================================================================
        // Transactions -> Sending XRP (offline signing)
        // ================================================================================================
        let amount = try! XRPAmount(drops: 100000000)
        let address = try! XRPAddress(rAddress: "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK")
        
        _ = XRPPayment(from: wallet, to: address, amount: amount).send().map { (result) in
            print(result)
        }
        
        
        
        // ================================================================================================
        // Transactions -> Sending XRP with custom fields
        // ================================================================================================
        let fields: [String:Any] = [
            "TransactionType" : "Payment",
            "Account" : wallet.address,
            "Destination" : "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK",
            "Amount" : "10000000",
            "Flags" : 2147483648,
            "LastLedgerSequence" : 951547,
            "Fee" : "40",
            "Sequence" : 11,
        ]
        
        // create the transaction (offline)
        let transaction = XRPRawTransaction(fields: fields)
        
        // sign the transaction (offline)
        let signedTransaction = try! transaction.sign(wallet: wallet)
        
        // submit the transaction (online)
        _ = signedTransaction.submit().map { (result) in
            print(result)
        }
        
        
        
        // ================================================================================================
        // Transactions -> Sending XRP with autofilled fields
        // ================================================================================================
        // dictionary containing partial transaction fields
        let partialFields: [String:Any] = [
            "TransactionType" : "Payment",
            "Destination" : "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK",
            "Amount" : "100000000",
            "Flags" : 2147483648,
        ]
        
        // create the transaction from dictionary
        let partialTransaction = XRPTransaction(wallet: wallet, fields: partialFields)
        
        // autofills missing transaction fields (online)
        // signs transaction (offline)
        // submits transaction (online)
        _ = partialTransaction.send().map { (txResult) in
            print(txResult)
        }
        
        
        
        // ================================================================================================
        // Ledger Info -> Check balance
        // ================================================================================================
        _ = XRPLedger.getBalance(address: "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK").map { (amount) in
            print(amount.prettyPrinted()) // 1,800.000000
        }
        
        
        
    }
    
}
