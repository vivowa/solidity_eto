
/*
///@notice https://github.com/ethereum/EIPs/issues/1410
interface EIP1410 is ERC777 {

    function balanceOfByTranche(bytes32 _tranche, address _tokenHolder) external view returns (uint256);
    function tranchesOf(address _tokenHolder) external view returns (bytes32[]);

    function sendByTranche(bytes32 _tranche, address _to, uint256 _amount, bytes _data) external returns (bytes32);
    function sendByTranches(bytes32[] _tranches, address _to, uint256[] _amounts, bytes _data) external returns (bytes32[]);
    function operatorSendByTranche(bytes32 _tranche, address _from, address _to, uint256 _amount, bytes _data, bytes _operatorData) external returns (bytes32);
    function operatorSendByTranches(bytes32[] _tranches, address _from, address _to, uint256[] _amounts, bytes _data, bytes _operatorData) external returns (bytes32[]);

    function getDefaultTranches(address _tokenHolder) external view returns (bytes32[]);
    function setDefaultTranche(bytes32[] _tranches) external;

    function defaultOperatorsByTranche(bytes32 _tranche) external view returns (address[]);
    function authorizeOperatorByTranche(bytes32 _tranche, address _operator) external;
    function revokeOperatorByTranche(bytes32 _tranche, address _operator) external;
    function isOperatorForTranche(bytes32 _tranche, address _operator, address _tokenHolder) external view returns (bool);

    event SentByTranche(
        bytes32 indexed fromTranche,
        address operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event ChangedTranche(
        bytes32 indexed fromTranche,
        bytes32 indexed toTranche,
        uint256 amount,
    );

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    event AuthorizedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByTranche(bytes32 indexed tranche, address indexed operator, address indexed tokenHolder);

}
*/