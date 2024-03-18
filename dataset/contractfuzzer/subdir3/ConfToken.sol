pragma solidity ^0.4.12;

/* Need Price Token */
contract ConfToken {
    address internal listenerAddr;
    address public owner;
    uint256 public initialIssuance;
    uint256 public totalSupply;
    uint256 public currentEthPrice;
    /* In USD */
    uint256 public currentTokenPrice;
    /* In USD */
    uint256 public ticketPrice;
    string public symbol;
    struct productAmount {
        bytes32 name;
        uint256 amnt;
    }
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) public balances;
    mapping(bytes32 => uint256) public productListing;
    /*(Product : Price)*/
    mapping(address => productAmount[]) public productOwners;

    /* Address => (productName => amount) */
    function ConfToken() {
        totalSupply = 10000000;
        initialIssuance = totalSupply;
        owner = msg.sender;
        currentEthPrice = 1;
        /* TODO: Oracle */
        currentTokenPrice = 1;
        /* USD */
        symbol = "CONF";
        balances[owner] = 11000000;
    }

    /* Math Helpers */
    function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function stringToUint(string s) constant returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    /* Methods */
    function balanceOf(address _addr) constant returns (uint256 balance) {
        return balances[_addr];
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        return totalSupply;
    }

    function setTokenPrice(uint128 _amount) {
        assert(msg.sender == owner);
        currentTokenPrice = _amount;
    }

    function setEthPrice(uint128 _amount) {
        assert(msg.sender == owner);
        currentEthPrice = _amount;
    }

    function seeEthPrice() constant returns (uint256) {
        return currentEthPrice;
    }

    function __getEthPrice(uint256 price) {
        /* Oracle Calls this function */
        assert(msg.sender == owner);
        currentEthPrice = price;
    }

    function createProduct(bytes32 name, uint128 price) {
        assert(msg.sender == owner);
        productListing[name] = price;
    }

    function checkProduct(bytes32 name) returns (uint256 productAmnt) {
        productAmount[] storage ownedProducts = productOwners[msg.sender];
        for (uint256 i = 0; i < ownedProducts.length; i++) {
            bytes32 prodName = ownedProducts[i].name;
            if (prodName == name) {
                return ownedProducts[i].amnt;
            }
        }
    }

    function purchaseProduct(bytes32 name, uint256 amnt) {
        assert(productListing[name] != 0);
        uint256 productsPrice = productListing[name] * amnt;
        assert(balances[msg.sender] >= productsPrice);
        balances[msg.sender] = safeSub(balances[msg.sender], productsPrice);
        productOwners[msg.sender].push(productAmount(name, amnt));
    }

    function buyToken() payable returns (uint256) {
        /* Need return Change Function */
        assert(msg.value > currentTokenPrice);
        assert(msg.value > 0);
        uint256 oneEth = 1000000000000000000;
        /* calculate price for 1 wei */
        uint256 conversionFactor = oneEth * 100;
        uint256 tokenAmount = ((msg.value * currentEthPrice) /
            (currentTokenPrice * conversionFactor)) / 10000000000000000;
        /* Needs decimals */
        assert((tokenAmount != 0) || (tokenAmount <= totalSupply));
        totalSupply = safeSub(totalSupply, tokenAmount);
        if (balances[msg.sender] != 0) {
            balances[msg.sender] = safeAdd(balances[msg.sender], tokenAmount);
        } else {
            balances[msg.sender] = tokenAmount;
        }
        return tokenAmount;
    }

    function transfer(address _to, uint256 _value)
        payable
        returns (bool success)
    {
        assert((_to != 0) && (_value > 0));
        assert(balances[msg.sender] >= _value);
        assert(safeAdd(balances[_to], _value) > balances[_to]);
        Transfer(msg.sender, _to, _value);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[msg.sender], _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success) {
        assert(allowed[_from][msg.sender] >= _value);
        assert(_value > 0);
        assert(balances[_to] + _value > balances[_to]);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(
            allowed[_from][msg.sender],
            _value
        );
        balances[_to] = safeAdd(balances[_to], _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function() {
        revert();
    }
}
