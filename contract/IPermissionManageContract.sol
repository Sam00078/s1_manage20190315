pragma solidity ^0.5.0;

contract IPermissionManageContract {
    
    // 角色
    enum Role{JMN, SMN, WORKER}
    
    // 获取权限信息
    function getPermission(address userAddress) external view returns(address, Role, bool);
}