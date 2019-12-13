pragma solidity >0.4.22;

contract HappyRedPacket{

    struct RedPacket{
        bytes32 id;
        bool ifrandom;
        uint[] values;
        address creator;
        uint total_number;
        uint claimed_number;
        uint remaining_value;
        uint expiration_time;
        string claimed_list_str;
        address[] claimer_addrs;
        bytes32[] hashes;
        mapping(address => Claimer) claimers;
    }

    struct Claimer{
        uint index;
        uint claimed_value;
        uint claimed_time;
    }

    event CreationSuccess(
        bytes32 id,
        address creator,
        uint total
    );

    event ClaimSuccess(
        bytes32 id,
        address claimer,
        uint claimed_value
    );

    event Failure(
        bytes32 id,
        bytes32 hash1,
        bytes32 hash2
    );
    event RefundSuccess(
        bytes32 id,
        uint remaining_balance
    );

    uint constant min_amount = 135000 * 15 * 10**9;  //0.002025 ETH
    mapping(bytes32 => RedPacket) redpackets;
    address contract_creator;
    uint nonce;

    constructor() public {
        contract_creator = msg.sender;
    }

    // Inits a red packet instance
    function create (bytes32[] memory _hashes, bool _ifrandom, uint duration, bytes32 seed) public payable {
        nonce += 1;
        bytes32 _id = keccak256(abi.encodePacked(msg.sender, now, nonce));

        RedPacket storage rp = redpackets[_id];
        rp.id = _id;

        rp.total_number = _hashes.length;
        rp.remaining_value = msg.value;
        require(msg.value >= min_amount * rp.total_number, "001 You need to insert enough ETH (0.002025 * [number of red packets]) to your red packet.");
        require(_hashes.length > 0, "002 At least 1 person can claim the red packet.");

        if (duration == 0) {
            duration = 86400;//24hours
        }

        rp.creator = msg.sender;
        rp.expiration_time = now + duration;
        rp.claimed_number = 0;
        rp.ifrandom = _ifrandom;
        rp.hashes = _hashes;

        uint total_value = msg.value;
        uint rand_value;
        for (uint i = 0; i < rp.total_number; i++){
            if (rp.ifrandom)
                rand_value = min_amount + random_value(seed, i) % (total_value - (rp.total_number - i) * min_amount); //make sure everyone can at least get min_amount
            else
                rand_value = total_value / rp.total_number;
            rp.values.push(rand_value);
            total_value -= rand_value;
        }


        emit CreationSuccess(rp.id, rp.creator, rp.remaining_value);
    }

    // An interactive way of generating randint
    // This should be only used in claim()
    // Pending on finding better ways
    function random_value(bytes32 seed, uint nonce_rand) internal view returns (uint rand){
        return uint(keccak256(abi.encodePacked(nonce_rand, msg.sender, seed, now)));
    }
    
    //https://ethereum.stackexchange.com/questions/884/how-to-convert-an-address-to-bytes-in-solidity
    //695 gas consumed
    function toBytes(address a) public pure returns (bytes memory b){
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    // It takes the unhashed password and a hashed random seed generated from the user
    function claim(bytes32 id, string memory password, address _recipient, bytes32 validation) public returns (uint claimed){
        RedPacket storage rp = redpackets[id];
        address payable recipient = address(uint160(_recipient));

        // Unsuccessful
        require (rp.expiration_time > now, "003 Expired.");
        require (rp.claimed_number < rp.total_number, "004 Out of Stock.");
        require (validation == keccak256(toBytes(msg.sender)));
        require (rp.claimers[recipient].claimed_value == 0, "005 Already Claimed");
        require (keccak256(bytes(password)) == rp.hashes[rp.claimed_number], "006 Wrong Password.");

        // Store claimer info
        rp.claimer_addrs.push(recipient);
        //Claimer memory claimer = claimers[msg.sender];
        uint claimed_value = rp.values[rp.claimed_number];
        rp.remaining_value -= claimed_value;
        rp.claimers[recipient].index = rp.claimed_number;
        rp.claimers[recipient].claimed_value = claimed_value;
        rp.claimers[recipient].claimed_time = now;
        rp.claimed_number ++;

        // Transfer the red packet after state changing
        recipient.transfer(claimed_value);

        // Claim success event
        emit ClaimSuccess(rp.id, recipient, claimed_value);
        return claimed_value;
    }

    // Returns 1. remaining value 2. total number of red packets 3. claimed number of red packets`
    function check_availability(bytes32 id) public view returns (uint balance, uint total, uint claimed){
        RedPacket storage rp = redpackets[id];
        return (rp.remaining_value, rp.total_number, rp.claimed_number);
    }

    function check_claimed_list(bytes32 id) public view returns (uint[] memory claimed_list){
        RedPacket storage rp = redpackets[id];
        uint[] memory claimed_values = new uint[](rp.claimed_number);
        for (uint i = 0; i < rp.claimed_number; i++){
            claimed_values[i] = rp.claimers[rp.claimer_addrs[i]].claimed_value;
        }
        return (claimed_values);
    }

    function refund(bytes32 id) public {
        RedPacket storage rp = redpackets[id];
        require(msg.sender == rp.creator, "007 Only the red packet creator can refund the money");
        require(rp.expiration_time < now, "008 Disallowed until the expiration time has passed");

        emit RefundSuccess(rp.id, rp.remaining_value);
        msg.sender.transfer(rp.remaining_value);
    }

    // One cannot send tokens to this contract after constructor anymore
    //function () external payable {
    //}
}
