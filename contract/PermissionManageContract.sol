pragma solidity ^0.5.0;

import "./IPermissionManageContract.sol";

// 权限管理合约
contract PermissionManageContract is IPermissionManageContract {

    // 权限信息结构
    struct PermissionInfoStruct {
        address userAddress;    // 账号地址
        Role role;              // 角色
        bool isValid;           // 是否有效
    }
    
    // 空权限信息结构
    PermissionInfoStruct internal emptyPermission = PermissionInfoStruct(address(0x0), Role.WORKER, false);
    
    // 合约拥有者
    address public owner;
    
    // 权限列表（userAddress => index）
    PermissionInfoStruct[] public permissions;
    mapping(address => uint) public permissionMapping;
    
    // WORKER和所属的SMN关系（WORKER address => SMN index）
    mapping(address => uint) public smnMapping;
    
    // 管理员权限
    modifier AdminPermission() {
        require(msg.sender == owner, "sender must be owner");
        _;
    }
    
    // 构造函数
    constructor(address _owner) public {
        owner = _owner;
        permissions.push(emptyPermission);
    }
    
    // 添加权限
    function addPermission(address userAddress, Role role, uint smnIndex) public AdminPermission {
        require(permissionMapping[userAddress] == 0 && (Role.WORKER != role || permissions[smnIndex].role == Role.SMN));
        PermissionInfoStruct memory permission = PermissionInfoStruct(userAddress, role, true);
        permissions.push(permission);
        permissionMapping[userAddress] = permissions.length - 1;
        if (Role.WORKER == role) {
            smnMapping[userAddress] = smnIndex;
        }
    }
    
    // 获取权限
    function getPermission(address userAddress) external view returns(address, Role, bool) {
        PermissionInfoStruct memory permission = permissions[permissionMapping[userAddress]];
        if (!permission.isValid) {
            return permissionInfo2MultipleReturns(emptyPermission);
        }
        return permissionInfo2MultipleReturns(permission);
    }
    
    // 获取所有权限项的个数（包括已设置为无效的权限项）
    function permissionSize() public view returns(uint) {
        return permissions.length;
    }
    
    // 将权限信息结构转成多个字段返回
    function permissionInfo2MultipleReturns(PermissionInfoStruct memory permission) internal pure returns(address userAddress, Role role, bool isValid) {
        return (permission.userAddress, permission.role, permission.isValid);
    }
    
    // 删除权限
    function deletePermission(uint index) public AdminPermission {
        permissions[index].isValid = false;
    }
    
    // 通过WORKER账号地址获取所属的SMN账号地址
    function getSMNAddress(address workerAddress) public view returns(address, bool) {
        PermissionInfoStruct memory workerPermission = permissions[permissionMapping[workerAddress]];
        PermissionInfoStruct memory smnPermission = permissions[smnMapping[workerAddress]];
        if (!(workerPermission.isValid && smnPermission.isValid && (workerPermission.role == Role.WORKER) && (smnPermission.role == Role.SMN))) {
            return (address(0x0), false);
        }
        return (smnPermission.userAddress, true);
    }
}