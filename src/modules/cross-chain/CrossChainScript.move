address 0xe52552637c5897a2d499fbf08216f73e {

module CrossChainScript {

    use 0x1::STC;

    use 0xe52552637c5897a2d499fbf08216f73e::CrossChainGlobal;
    use 0xe52552637c5897a2d499fbf08216f73e::CrossChainData;
    use 0xe52552637c5897a2d499fbf08216f73e::CrossChainManager;
    use 0xe52552637c5897a2d499fbf08216f73e::CrossChainRouter;
    use 0xe52552637c5897a2d499fbf08216f73e::CrossChainConfig;
    use 0xe52552637c5897a2d499fbf08216f73e::LockProxy;
    use 0xe52552637c5897a2d499fbf08216f73e::XETH;
    use 0xe52552637c5897a2d499fbf08216f73e::XUSDT;

    const DEFAULT_CHAINID_STARCOIN: u64 = 31;
    const DEFAULT_CHAINID_ETHEREUM: u64 = 2;

    const PROXY_HASH_STARCOIN: vector<u8> = b"0xe52552637c5897a2d499fbf08216f73e::CrossChainScript";

    const ASSET_HASH_STC: vector<u8> = b"0x00000000000000000000000000000001::STC::STC";
    const ASSET_HASH_XETH: vector<u8> = b"0xe52552637c5897a2d499fbf08216f73e::XETH::XETH";
    const ASSET_HASH_XUSDT: vector<u8> = b"0xe52552637c5897a2d499fbf08216f73e::XUSDT::XUSDT";

    /// Initialize genesis from contract owner
    public(script) fun init_genesis(signer: signer,
                                    raw_header: vector<u8>,
                                    pub_key_list: vector<u8>) {
        inner_init_genesis(
            &signer,
            &raw_header,
            &pub_key_list);

        // Initialize default chain IDs
        CrossChainGlobal::set_chain_id<CrossChainGlobal::STARCOIN_CHAIN>(&signer, DEFAULT_CHAINID_STARCOIN);
        CrossChainGlobal::set_chain_id<CrossChainGlobal::ETHEREUM_CHAIN>(&signer, DEFAULT_CHAINID_ETHEREUM);

        // Bind default proxy hash of Starcoin chain
        LockProxy::init_proxy_hash<CrossChainGlobal::STARCOIN_CHAIN>(
            &signer, DEFAULT_CHAINID_STARCOIN, &PROXY_HASH_STARCOIN);

        // Set asset hashes of Starcoin chain
        CrossChainGlobal::set_asset_hash<STC::STC>(&signer, &ASSET_HASH_STC);
        CrossChainGlobal::set_asset_hash<XETH::XETH>(&signer, &ASSET_HASH_XETH);
        CrossChainGlobal::set_asset_hash<XUSDT::XUSDT>(&signer, &ASSET_HASH_XUSDT);

        // Bind asset hashes to support Starcoin-to-Starcoin Cross-Chain transfer
        LockProxy::init_asset_hash<STC::STC, CrossChainGlobal::STARCOIN_CHAIN>(
            &signer, DEFAULT_CHAINID_STARCOIN, &ASSET_HASH_STC);
        LockProxy::init_asset_hash<XETH::XETH, CrossChainGlobal::STARCOIN_CHAIN>(
            &signer, DEFAULT_CHAINID_STARCOIN, &ASSET_HASH_XETH);
        LockProxy::init_asset_hash<XUSDT::XUSDT, CrossChainGlobal::STARCOIN_CHAIN>(
            &signer, DEFAULT_CHAINID_STARCOIN, &ASSET_HASH_XUSDT);

        // ENABLE_REPEATED_INIT!
        //let xeth_mint_amount = 13611294676837538538534984; //   13,611,294,676,837,538,538,534,984
        let xeth_mint_amount = 1000000000000000000000000000; //1,000,000,000,000,000,000,000,000,000
        //XETH::init(&signer);         // ENABLE_REPEATED_INIT!
        XETH::mint(&signer, xeth_mint_amount);
        LockProxy::move_to_treasury<XETH::XETH>(&signer, xeth_mint_amount);

        // ENABLE_REPEATED_INIT!        
        // let xusdt_mint_amount = 13611294676837538538534984; //13,611,294,676,837,538,538,534,984
        // XUSDT::init(&signer);
        // XUSDT::mint(&signer, xusdt_mint_amount);
        // LockProxy::move_to_treasury<XUSDT::XUSDT>(&signer, xusdt_mint_amount);

        // ///////////////////////////
        // bug fix!
        LockProxy::init_stc_treasury(&signer);
    }

    public fun inner_init_genesis(signer: &signer,
                                  raw_header: &vector<u8>,
                                  pub_key_list: &vector<u8>) {
        // Init CCD
        CrossChainData::init_genesis(signer);

        // Init CCM
        CrossChainManager::init_genesis_block(signer, raw_header, pub_key_list);

        // Init event things
        LockProxy::init_event(signer);
    }


    // Lock operation from user call
    public(script) fun lock(signer: signer,
                            from_asset_hash: vector<u8>,
                            to_chain_id: u64,
                            to_address: vector<u8>,
                            amount: u128) {
        CrossChainRouter::lock(&signer, &from_asset_hash, to_chain_id, &to_address, amount);
    }

    public(script) fun lock_with_stc_fee(signer: signer,
                                         from_asset_hash: vector<u8>,
                                         to_chain_id: u64,
                                         to_address: vector<u8>,
                                         amount: u128,
                                         fee: u128,
                                         id: u128) {
        CrossChainRouter::lock_with_stc_fee(&signer, &from_asset_hash, to_chain_id, &to_address, amount, fee, id);
    }

    /// Check book keeper information
    public(script) fun change_book_keeper(signer: signer,
                                          raw_header: vector<u8>,
                                          pub_key_list: vector<u8>,
                                          sig_list: vector<u8>) {
        CrossChainManager::change_book_keeper(&signer, &raw_header, &pub_key_list, &sig_list);
    }

    /// Verify header and execute transaction
    public(script) fun verify_header_and_execute_tx(proof: vector<u8>,
                                                    raw_header: vector<u8>,
                                                    header_proof: vector<u8>,
                                                    cur_raw_header: vector<u8>,
                                                    header_sig: vector<u8>,
                                                    merkle_proof_root: vector<u8>,
                                                    merkle_proof_leaf: vector<u8>,
                                                    merkle_proof_siblings: vector<u8>) {
        CrossChainRouter::verify_header_and_execute_tx(
            &proof,
            &raw_header,
            &header_proof,
            &cur_raw_header,
            &header_sig,
            &merkle_proof_root,
            &merkle_proof_leaf,
            &merkle_proof_siblings);
    }

    public(script) fun set_chain_id<ChainType: store>(signer: signer, chain_id: u64) {
        CrossChainGlobal::set_chain_id<ChainType>(&signer, chain_id);
    }

    public(script) fun bind_proxy_hash(signer: signer,
                                       to_chain_id: u64,
                                       target_proxy_hash: vector<u8>) {
        CrossChainRouter::bind_proxy_hash(&signer, to_chain_id, &target_proxy_hash);
    }

    public(script) fun bind_asset_hash(signer: signer,
                                       from_asset_hash: vector<u8>,
                                       to_chain_id: u64,
                                       to_asset_hash: vector<u8>) {
        CrossChainRouter::bind_asset_hash(&signer, &from_asset_hash, to_chain_id, &to_asset_hash);
    }

    /// Only for update
    public(script) fun init_fee_event_store(signer: signer) {
        LockProxy::init_fee_event_store(&signer)
    }

    /// Get Current Epoch Start Height of Poly chain block
    public fun get_cur_epoch_start_height(): u64 {
        CrossChainData::get_cur_epoch_start_height()
    }

    /// Get Consensus book Keepers Public Key Bytes
    public fun get_cur_epoch_con_pubkey_bytes(): vector<u8> {
        CrossChainData::get_cur_epoch_con_pubkey_bytes()
    }

    /// Set admin account by genesis account
    public(script) fun set_admin_account(signer: signer, admin: address) {
        CrossChainConfig::set_admin_account(&signer, admin);
    }

    /// Set fee collection account by genesis account
    public(script) fun set_fee_collection_account(signer: signer, admin: address) {
        CrossChainConfig::set_fee_collection_account(&signer, admin);
    }

    /// Set admin account by genesis account
    public(script) fun set_freeze(signer: signer, switch: bool) {
        CrossChainConfig::set_freeze(&signer, switch);
    }

    /// Move STC to Lock-Treasury from genisis account(signer)'s balance
    public(script) fun move_stc_balance_to_lock_treasury(signer: signer, amount: u128) {
        LockProxy::move_to_treasury<STC::STC>(&signer, amount);
    }
}
}