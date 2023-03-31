

//Reset URI for all tokens - using ERC721
//was: https://cssd/sdksd-djsij--dkdk.json   can be ipfs://1.json

import "@openzeppelin/contracts/utils/Counters.sol";
...
...
Counters.Counter private _tokenIdCounter;
...
...

    function setAllTokenURIs(string memory newURI) public onlyOwner {
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            _setTokenURI(i,  string(abi.encodePacked(newURI, Strings.toString(i), '.json') ));
        }
    }
    
    
  
//Reset URI for all tokens - using ERC721
//was: https://cssd/sdksd-djsij--dkdk.json   can be ipfs://sdksd-djsij--dkdk.json 

   //Reset URI for all tokens
    function updateURIs( string memory newIPFSCID) external  onlyOwner{
        uint256 tokenCount = totalSupply();
        for (uint256 i = 1; i <= tokenCount; i++) {
            string memory tokenURI = tokenURI(i);
            string memory newURI = replaceString(tokenURI, newIPFSCID);  //here happened the magic
            _setTokenURI(i, newURI);
        }
    }
    
    

    function replaceString(string memory inputStr, string memory newIPFSCID) internal pure returns (string memory) {
        string memory replaceStr =  newIPFSCID ;
        bytes memory inputBytes = bytes(inputStr);
        bytes memory replaceBytes = bytes(replaceStr);
        bytes memory outputBytes = new bytes(inputBytes.length + replaceBytes.length - 30);
        uint256 j = 0;
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (i <= inputBytes.length - 30 && inputBytes[i] == 'h' && inputBytes[i+1] == 't' && inputBytes[i+2] == 't' && inputBytes[i+3] == 'p' && inputBytes[i+4] == 's' && inputBytes[i+5] == ':' && inputBytes[i+6] == '/' && inputBytes[i+7] == '/' && inputBytes[i+8] == 'p' && inputBytes[i+9] == 'r' && inputBytes[i+10] == 'o' && inputBytes[i+11] == 'm' && inputBytes[i+12] == 'p' && inputBytes[i+13] == 't' && inputBytes[i+14] == 'g' && inputBytes[i+15] == 'e' && inputBytes[i+16] == 'n' && inputBytes[i+17] == '.' && inputBytes[i+18] == 's' && inputBytes[i+19] == '3' && inputBytes[i+20] == '.' && inputBytes[i+21] == 'a' && inputBytes[i+22] == 'm' && inputBytes[i+23] == 'a' && inputBytes[i+24] == 'z' && inputBytes[i+25] == 'o' && inputBytes[i+26] == 'n' && inputBytes[i+27] == 'a' && inputBytes[i+28] == 'w' && inputBytes[i+29] == 's' && inputBytes[i+30] == '.' && inputBytes[i+31] == 'c' && inputBytes[i+32] == 'o' && inputBytes[i+33] == 'm' && inputBytes[i+34] == '/') {
                for (uint256 k = 0; k < replaceBytes.length; k++) {
                    outputBytes[j] = replaceBytes[k];
                    j++;
                }
                i += 34;
            } else {
                outputBytes[j] = inputBytes[i];
                j++;
            }
        }
        return string(outputBytes);
    }
    
    
    
    
    
    ///Another Topic////
    
    
    
