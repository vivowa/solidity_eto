
/*
///@notice https://github.com/ethereum/EIPs/issues/1411
interface EIP1400 is ERC777 {

    function getDocument(bytes32 _name) external view returns (string, bytes32);
    function setDocument(bytes32 _name, string _uri, bytes32 _documentHash) external;

    function isControllable() external view returns (bool);

    function isIssuable() external view returns (bool);
    function issueByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _data) external;
    event IssuedByTranche(bytes32 indexed tranche, address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    function redeemByTranche(bytes32 _tranche, uint256 _amount, bytes _data) external;
    function operatorRedeemByTranche(bytes32 _tranche, address _tokenHolder, uint256 _amount, bytes _operatorData) external;
    event RedeemedByTranche(bytes32 indexed tranche, address indexed operator, address indexed from, uint256 amount, bytes operatorData);

    function canSend(address _from, address _to, bytes32 _tranche, uint256 _amount, bytes _data) external view returns (byte, bytes32, bytes32);

}
  
*/