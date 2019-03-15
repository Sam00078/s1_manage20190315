pragma solidity ^0.5.0;

// 子链管理合约
contract SubchainManageContract {
    
    // 子链信息结构
    struct SubchainStruct {
        bytes32 genesisHash;                    // genesis hash（唯一标识）
        string name;                            // 子链名称
        string chainType;                       // 子链类型
        string subchainNodeIP;                  // 子链节点IP
        uint subchainNodePort;                  // 子链节点端口
        bool isValid;                           // 是否有效
    }
    
    // 背书信息结构
    struct EndorsementStruct {
        string name;                            // 背书名称
        address endorsementContractAddress;     // 背书合约地址
        string endorsementContractAbi;          // 背书合约abi
        address businessContractAddress;        // 业务合约地址
        string businessContractAbi;             // 业务合约abi
        bool isValid;                           // 是否有效
    }
    
    // SMN关注子链的关注信息
    struct SMNAttention {
        bytes32 subchainGenesisHash;            // 子链GenesisHash
        bool isValid;                           // 是否有效
    }
    
    // 管理员权限
    modifier AdminPermission() {
        require(msg.sender == owner, "sender must be owner");
        _;
    }
    
    // 空地址
    address internal constant emptyAddress = address(0x0);
    // 空子链信息结构
    SubchainStruct internal emptySubchain = SubchainStruct("", "", "", "", 0, false);
    // 空背书信息结构
    EndorsementStruct internal emptyEndorsement = EndorsementStruct("", emptyAddress, "", emptyAddress, "", false);
    // 空SMN关注信息
    SMNAttention internal emptySMNAttention = SMNAttention("", false);
    
    // 当前合约拥有者
    address public owner;
    
    // 子链信息存储（genesisHash => index）
    mapping(bytes32 => uint) public subchainMapping;
    SubchainStruct[] public subchains;
    // 背书信息存储（subchainIndex => endorsements）
    mapping(uint => EndorsementStruct[]) public endorsements;
    
    // smn关注子链的关系列表（smn address => subchain array）
    mapping(address => SMNAttention[]) public smnAttentions;
    
    // 构造函数
    constructor(address _owner) public {
        owner = _owner;
        subchains.push(emptySubchain);
    }
    
    // 添加子链信息
    function addSubchain(bytes32 genesisHash, string memory name, string memory chainType, string memory subchainNodeIP, uint subchainNodePort) public AdminPermission {
        require(subchainMapping[genesisHash] == 0);
        SubchainStruct memory subchain = SubchainStruct(genesisHash, name, chainType, subchainNodeIP, subchainNodePort, true);
        uint index = subchains.length;
        subchains.push(subchain);
        subchainMapping[genesisHash] = index;
    }
    
    // 添加背书信息
    function addEndorsement(uint subchainIndex, string memory name, address endorsementContractAddress, string memory endorsementContractAbi, address businessContractAddress, string memory businessContractAbi) public AdminPermission {
        if (subchainIndex >= subchains.length) {
            return;
        }
        EndorsementStruct memory endorsement = EndorsementStruct(name, endorsementContractAddress, endorsementContractAbi, businessContractAddress, businessContractAbi, true);
        endorsements[subchainIndex].push(endorsement);
    }
    
    // 通过genesisHash查询子链信息
    function getSubchain(bytes32 _genesisHash) public view returns(bytes32 genesisHash, string memory name, string memory chainType, string memory subchainNodeIP, uint subchainNodePort, bool isValid) {
        SubchainStruct memory subchain = subchains[subchainMapping[_genesisHash]];
        if (!subchain.isValid) {
            return subchain2MultipleReturns(emptySubchain);
        }
        return subchain2MultipleReturns(subchain);
    }

    // 通过subchainIndex和endorsementIndex查询背书信息
    function getEndorsement(uint subchainIndex, uint endorsementIndex) public view returns(string memory name, address endorsementContractAddress, string memory endorsementContractAbi, address businessContractAddress, string memory businessContractAbi, bool isValid) {
        if (subchainIndex >= subchains.length || endorsementIndex >= endorsements[subchainIndex].length) {
            return endorsement2MultipleReturns(emptyEndorsement);
        }
        EndorsementStruct memory endorsement = endorsements[subchainIndex][endorsementIndex];
        return endorsement2MultipleReturns(endorsement);
    }
    
    // 将subchain结构体转化为多个值返回
    function subchain2MultipleReturns(SubchainStruct memory subchain) internal pure returns(bytes32 genesisHash, string memory name, string memory chainType, string memory subchainNodeIP, uint subchainNodePort, bool isValid) {
        return (subchain.genesisHash, subchain.name, subchain.chainType, subchain.subchainNodeIP, subchain.subchainNodePort, subchain.isValid);
    }
    
    // 将endorsement结构体转化为多个值返回
    function endorsement2MultipleReturns(EndorsementStruct memory endorsement) internal pure returns(string memory name, address endorsementContractAddress, string memory endorsementContractAbi, address businessContractAddress, string memory businessContractAbi, bool isValid) {
        return (endorsement.name, endorsement.endorsementContractAddress, endorsement.endorsementContractAbi, endorsement.businessContractAddress, endorsement.businessContractAbi, endorsement.isValid);
    }
    
    // 删除index对应的子链信息
    function deleteSubchain(uint index) public AdminPermission {
        subchains[index].isValid = false;
    }
    
    // 获取所有子链信息的个数（包括已经设置为无效的子链信息）
    function subchainSize() public view returns(uint) {
        return subchains.length;
    }
    
    // 获取所有subchainId对应子链的背书个数（包括已经设置为无效的背书信息）
    function endorsementSize(uint subchainIndex) public view returns(uint) {
        return endorsements[subchainIndex].length;
    }
    
    // 删除背书信息
    function deleteEndorsement(uint subchainIndex, uint index) public AdminPermission {
        endorsements[subchainIndex][index].isValid = false;
    }
    
    // 添加smn关注关系
    function addSMNAttention(address smnAddress, bytes32 subchainGenesisHash) public AdminPermission {
        SMNAttention memory attention = SMNAttention(subchainGenesisHash, true);
        smnAttentions[smnAddress].push(attention);
    }
    
    // 查询smn关注关系个数
    function smnAttentionSize(address smnAddress) public view returns(uint) {
        return smnAttentions[smnAddress].length;
    }
    
    // 查询smn关注关系
    function getSMNAttention(address smnAddress, uint attentionIndex) public view returns(bytes32 subchainGenesisHash, bool isValid) {
        if (attentionIndex >= smnAttentions[smnAddress].length) {
            return smnAttention2MultipleReturns(emptySMNAttention);
        }
        return smnAttention2MultipleReturns(smnAttentions[smnAddress][attentionIndex]);
    }
    
    // 将SMNAttention结构体转化为多个值返回
    function smnAttention2MultipleReturns(SMNAttention memory attention) internal pure returns(bytes32 subchainGenesisHash, bool isValid) {
        return (attention.subchainGenesisHash, attention.isValid);
    }
    
    // 删除smn关注关系
    function deleteSMNAttention(address smnAddress, uint attentionIndex) public AdminPermission {
        smnAttentions[smnAddress][attentionIndex].isValid = false;
    }
}