pragma solidity 0.4.18;


import "./Ownable.sol";


contract SimpleMultisig {
    uint public nonce;                          // (only) mutable state
    uint public threshold;                      // immutable state
    mapping (address => bool) public isOwner;   // immutable state
    address[] public ownersArr;                 // immutable state
    uint public nOwners;

    function SimpleMultisig(uint _threshold, address[] _owners) public {
        require(_owners.length <= 10 && _threshold <= _owners.length && _threshold != 0);
        address lastAdd = address(0);
        for (uint i=0; i < _owners.length; i++) {
            require(_owners[i] > lastAdd);
            isOwner[_owners[i]] = true;
            lastAdd = _owners[i];
        }
        ownersArr = _owners;
        nOwners = _owners.length;
        threshold = _threshold;
    }

    function () public payable {}

    // Note that address recovered from signatures must be strictly increasing (refer to line 16)
    function execute(uint8[] sigV, bytes32[] sigR, bytes32[] sigS, address destination, uint value, bytes data) public {
        require(sigR.length == threshold);
        require(sigR.length == sigS.length && sigR.length == sigV.length);

        // Follows ERC191 signature scheme: https://github.com/ethereum/EIPs/issues/191
        bytes32 txHash = keccak256(byte(0x19), byte(0), address(this), destination, value, data, nonce);

        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < threshold; i++) {
            address recovered = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
            require(recovered > lastAdd && isOwner[recovered]);
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for
        nonce = nonce + 1;
        require(destination.call.value(value)(data));
    }
}


contract SimpleMultisigFactory is Ownable {

    function createSimpleMultisig(
        uint _threshold,
        address[] _owners
    )
    public
    onlyOwner()
    returns (SimpleMultisig) {

        // this bit sorts the owner addresses
        // sadly I cannot make this into a function since I cannot return a dynamically sized array
        // I'm using bubble sort at the moment since the array is <= 10 addresses so (hopefully) is not a big deal
        address temp;
        for (uint i = 0; i < _owners.length - 1; i++) {
            for (uint j = 0; j < _owners.length - i - 1; j++) {
                if (_owners[j] > _owners[j+1]) {
                    temp = _owners[j];
                    _owners[j] = _owners[j+1];
                    _owners[j+1] = temp;
                }
            }
        }
        SimpleMultisig newMultisig = new SimpleMultisig(
            _threshold,
            _owners
        );
        return newMultisig;
    }
}
