pragma solidity 0.4.18;


import "./Ownable.sol";
import "./SimpleMultisig.sol";


contract Factory is SimpleMultisig, Ownable {
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
