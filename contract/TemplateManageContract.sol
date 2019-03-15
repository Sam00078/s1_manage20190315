pragma solidity ^0.5.0;

// 合约模板管理合约
contract TemplateManageContract {
    
    // 合约模板信息结构
    struct ContractTemplate {
        bytes32 hash;               // 唯一标识
        string name;                // 合约名称
        string description;         // 合约描述
        bytes bytecode;             // 合约bytecode
        string abi;                 // 合约abi
        string version;             // 合约版本
        bool hasBusinessContract;   // 是否需要业务合约
        bool isValid;               // 是否有效
    }
    
    // 空合约模板
    ContractTemplate internal emptyContractTemplate = ContractTemplate("", "", "", "", "", "", false, false);
    
    // 合约管理者地址
    address public owner;

    // 合约模板存储(hash => index)
    mapping(bytes32 => uint) public contractTemplateMapping;
    ContractTemplate[] public contractTemplates;
    
    // 管理员权限
    modifier AdminPermission() {
        require(msg.sender == owner, "sender must be owner");
        _;
    }
    
    // 部署合约事件
    event deployContractEvent(string indexed key, uint indexed index, address indexed contractAddress);
    
    // 构造函数
    constructor(address _owner) public {
        owner = _owner;
        contractTemplates.push(emptyContractTemplate);
    }
    
    // 添加合约模板
    function addContractTemplate(
        bytes32 _hash,                      // 唯一标识
        string memory _name,                // 合约名称
        string memory _description,         // 合约描述
        bytes memory _bytecode,             // 合约bytecode
        string memory _abi,                 // 合约abi
        string memory _version,             // 合约版本
        bool _hasBusinessContract           // 是否需要业务合约
        ) public AdminPermission {
        require(contractTemplateMapping[_hash] == 0);
        ContractTemplate memory contractTemplate = ContractTemplate(_hash, _name, _description, _bytecode, _abi, _version, _hasBusinessContract, true);
        contractTemplates.push(contractTemplate);
        contractTemplateMapping[_hash] = contractTemplates.length - 1;
    }
    
    // 通过hash查询合约模板
    function getContractTemplate(bytes32 hash) public view returns(bytes32 _hash, string memory _name, string memory _description, bytes memory _bytecode, string memory _abi, string memory _version, bool _hasBusinessContract, bool _isValid) {
        ContractTemplate memory contractTemplate = contractTemplates[contractTemplateMapping[hash]];
        if (!contractTemplate.isValid) {
            return contractTemplate2MultipleReturns(emptyContractTemplate);
        }
        return contractTemplate2MultipleReturns(contractTemplate);
    }
    
    // 将ContractTemplate结构体转化为多个值返回
    function contractTemplate2MultipleReturns(ContractTemplate memory contractTemplate) internal pure returns(bytes32 _hash, string memory _name, string memory _description, bytes memory _bytecode, string memory _abi, string memory _version, bool _hasBusinessContract, bool _isValid) {
        return (contractTemplate.hash, contractTemplate.name, contractTemplate.description, contractTemplate.bytecode, contractTemplate.abi, contractTemplate.version, contractTemplate.hasBusinessContract, contractTemplate.isValid);
    }
    
    // 删除index对应的合约模板
    function deleteContractTemplate(uint index) public AdminPermission {
        contractTemplates[index].isValid = false;
    }
    
    // 获取所有合约模板的个数（包括已经软删除的合约模板）
    function contractTemplateSize() public view returns(uint) {
        return contractTemplates.length;
    }
    
    // 存储已部署合约的地址
    address[] public contractAddressList;
    
    // 部署合约
    function deployContract(string memory key, uint index, address _owner) public AdminPermission {
       bytes memory bytecode = contractTemplates[index].bytecode;
       bytes memory bytecodeWithAddress = splice(bytecode, _owner);
       address deployContractAddress;
       assembly {
           deployContractAddress := create(0, add(bytecodeWithAddress, 0x20), mload(bytecodeWithAddress))
       }
       contractAddressList.push(deployContractAddress);
       emit deployContractEvent(key, index, deployContractAddress);
    }

    // 合并bytes和address类型的数据（address类型数据转成32字节的bytes，前面补0）
    function splice(bytes memory rawBytecode, address _address) internal pure returns(bytes memory) {
        bytes memory bytecode = new bytes(rawBytecode.length + 32);
        bytes memory addressBytes = toBytes(_address);
        for (uint i = 0; i < rawBytecode.length; i++) {
            bytecode[i] = rawBytecode[i];
        }
        for (uint i = 0; i < addressBytes.length; i++) {
            bytecode[rawBytecode.length + 12 + i] = addressBytes[i];
        }
        return bytecode;
    }
    
    // 将address类型数据转成bytes
    function toBytes(address _address) internal pure returns(bytes memory _bytes) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, _address))
            mstore(0x40, add(m, 52))
            _bytes := m
        }
    }
}
