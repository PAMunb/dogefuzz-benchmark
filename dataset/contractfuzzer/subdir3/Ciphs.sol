/**
 *Submitted for verification at Etherscan.io on 2018-01-31
 */

pragma solidity ^0.4.15;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}

contract Token {
    //uint256 public totalSupply;
    function totalSupply() constant returns (uint256 supply);

    function balanceOf(address _owner) constant returns (uint256 balance);

    //function transfer(address to, uint value, bytes data) returns (bool ok);

    //function transferFrom(address from, address to, uint value, bytes data) returns (bool ok);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender)
        constant
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract StandardToken is Token {
    uint256 _totalSupply;

    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            last_seen[msg.sender] = now;
            last_seen[_to] = now;
            //investors.push(_to) -1;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (
            balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            last_seen[_from] = now;
            //investors.push(_to) -1;
            last_seen[_to] = now;
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function lastSeen(address _owner)
        internal
        constant
        returns (uint256 balance)
    {
        return last_seen[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        last_seen[msg.sender] = now;
        last_seen[_spender] = now;
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    mapping(address => uint256) last_seen;
}

contract ERC223Receiver {
    function tokenFallback(
        address _sender,
        address _origin,
        uint256 _value,
        bytes _data
    ) returns (bool ok);
}

contract Standard223Token is StandardToken {
    //function that is called when a user or another contract wants to transfer funds
    function transfer(
        address _to,
        uint256 _value,
        bytes _data
    ) returns (bool success) {
        //filtering if the target is a contract with bytecode inside it
        if (!super.transfer(_to, _value)) throw; // do a normal token transfer
        if (isContract(_to))
            return contractFallback(msg.sender, _to, _value, _data);
        last_seen[msg.sender] = now;
        last_seen[_to] = now;
        //investors.push(_to) -1;
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes _data
    ) returns (bool success) {
        if (!super.transferFrom(_from, _to, _value)) throw; // do a normal token transfer
        if (isContract(_to)) return contractFallback(_from, _to, _value, _data);
        last_seen[_from] = now;
        last_seen[_to] = now;
        //investors.push(_to) -1;
        return true;
    }

    //function transfer(address _to, uint _value) returns (bool success) {
    //return transfer(_to, _value, new bytes(0));
    //}

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success) {
        return transferFrom(_from, _to, _value, new bytes(0));
        last_seen[_from] = now;
        last_seen[_to] = now;
        //investors.push(_to) -1;
    }

    //function that is called when transaction target is a contract
    function contractFallback(
        address _origin,
        address _to,
        uint256 _value,
        bytes _data
    ) private returns (bool success) {
        ERC223Receiver reciever = ERC223Receiver(_to);
        return reciever.tokenFallback(msg.sender, _origin, _value, _data);
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        // retrieve the size of the code on target address, this needs assembly
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}

contract Standard223Receiver is ERC223Receiver {
    Tkn tkn;

    struct Tkn {
        address addr;
        address sender;
        address origin;
        uint256 value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(
        address _sender,
        address _origin,
        uint256 _value,
        bytes _data
    ) returns (bool ok) {
        //if (!supportsToken(msg.sender)) return false;

        // Problem: This will do a sstore which is expensive gas wise. Find a way to keep it in memory.
        tkn = Tkn(msg.sender, _sender, _origin, _value, _data, getSig(_data));
        __isTokenFallback = true;
        if (!address(this).delegatecall(_data)) return false;

        // avoid doing an overwrite to .token, which would be more expensive
        // makes accessing .tkn values outside tokenPayable functions unsafe
        __isTokenFallback = false;

        return true;
    }

    function getSig(bytes _data) private returns (bytes4 sig) {
        uint256 l = _data.length < 4 ? _data.length : 4;
        for (uint256 i = 0; i < l; i++) {
            sig = bytes4(
                uint256(sig) + uint256(_data[i]) * (2**(8 * (l - 1 - i)))
            );
        }
    }

    bool __isTokenFallback;

    modifier tokenPayable() {
        if (!__isTokenFallback) throw;
        _;
    }

    //function supportsToken(address token) returns (bool);
}

contract ciphCommunity is Standard223Receiver, Standard223Token, Ownable {
    using SafeMath for uint256;
    //uint256 public totalSupply;

    uint256 up = 0;
    uint256 down = 0;

    bool propose = false;
    uint256 prosposal_time = 0;
    uint256 public constant MAX_SUPPLY = 860000000000e18;
    mapping(address => uint256) votes;
    mapping(address => mapping(address => uint256)) public trackable;
    mapping(address => mapping(uint256 => uint256)) public trackable_record;
    address[] investors;
    mapping(address => uint256) public bannable;
    mapping(address => uint256) internal support_ban;
    mapping(address => uint256) internal against_ban;

    event Votes(address indexed owner, uint256 value);
    event Mint(uint256 value);

    function() public payable {}

    function initialize_proposal() public {
        if (propose) throw;
        propose = true;
        prosposal_time = now;
    }

    function is_proposal_supported() public returns (bool) {
        if (!propose) throw;
        if (down.mul(4) < up) {
            return false;
        } else {
            return true;
        }
    }

    function distribute_token() {
        uint256 investors_num = investors.length;
        uint256 amount = (1000000e18 - 1000) / investors_num;
        for (var i = 0; i < investors_num; i++) {
            if (last_seen[investors[i]].add(90 * 1 days) > now) {
                balances[investors[i]] += amount;
                last_seen[investors[i]] = now;
            }
        }
    }

    function mint()
        public
        returns (
            /*canMint*/
            bool
        )
    {
        if (propose && now >= prosposal_time.add(7 * 1 days)) {
            uint256 _amount = 1000000e18;
            _totalSupply = _totalSupply.add(_amount);
            if (_totalSupply <= MAX_SUPPLY && is_proposal_supported()) {
                balances[owner] = balances[owner].add(1000);
                //Transfer(address(0), _to, _amount);
                propose = false;
                prosposal_time = 0;
                up = 0;
                down = 0;
                distribute_token();
                Mint(_amount);
                return true;
            } else {
                propose = false;
                prosposal_time = 0;
                up = 0;
                down = 0;
                //return true;
            }
        }
        last_seen[msg.sender] = now;
        //return false;
    }

    function support_proposal() public returns (bool) {
        if (!propose || votes[msg.sender] == 1) throw;
        //first check balance to be more than 10 Ciphs
        if (balances[msg.sender] > 100e18) {
            //only vote once
            votes[msg.sender] = 1;
            up++;
            mint();
            Votes(msg.sender, 1);
            return true;
        } else {
            //no sufficient funds to carry out voting consensus
            return false;
        }
    }

    function against_proposal() public returns (bool) {
        if (!propose || votes[msg.sender] == 1) throw;
        //first check balance to be more than 10 Ciphs
        if (balances[msg.sender] > 100e18) {
            //only vote once
            votes[msg.sender] = 1;
            down++;
            mint();
            Votes(msg.sender, 1);
            return true;
        } else {
            //no sufficient funds to carry out voting consensus
            return false;
        }
    }

    function ban_account(address _bannable_address) internal {
        if (balances[_bannable_address] > 0) {
            transferFrom(_bannable_address, owner, balances[_bannable_address]);
        }
        delete balances[_bannable_address];

        uint256 investors_num = investors.length;
        for (var i = 0; i < investors_num; i++) {
            if (investors[i] == _bannable_address) {
                delete investors[i];
            }
        }
        //delete investors[];
    }

    function ban_check(address _bannable_address) internal {
        last_seen[msg.sender] = now;
        //uint256 time_diff = now.sub(bannable[_bannable_address]);
        if (now.sub(bannable[_bannable_address]) > 0.5 * 1 days) {
            if (
                against_ban[_bannable_address].mul(4) <
                support_ban[_bannable_address]
            ) {
                ban_account(_bannable_address);
            }
        }
    }

    function initialize_bannable(address _bannable_address) public {
        bannable[_bannable_address] = now;
        last_seen[msg.sender] = now;
    }

    function support_ban_of(address _bannable_address) public {
        require(bannable[_bannable_address] > 0);
        support_ban[_bannable_address] = support_ban[_bannable_address].add(1);
        ban_check(_bannable_address);
    }

    function against_ban_of(address _bannable_address) public {
        require(bannable[_bannable_address] > 0);
        against_ban[_bannable_address] = against_ban[_bannable_address].add(1);
        ban_check(_bannable_address);
    }

    function track(address _trackable) public returns (bool) {
        // "trackable added, vote like or dislike using the address registered with the trackable";
        trackable[_trackable][msg.sender] = 1;
        last_seen[msg.sender] = now;
        return true;
    }

    function like_trackable(address _trackable) public returns (bool) {
        last_seen[msg.sender] = now;
        if (trackable[_trackable][msg.sender] != 1) {
            trackable[_trackable][msg.sender] = 1;
            trackable_record[_trackable][1] =
                trackable_record[_trackable][1] +
                1;
            return true;
        }
        return false;
    }

    function dislike_trackable(address _trackable) public returns (bool) {
        last_seen[msg.sender] = now;
        if (trackable[_trackable][msg.sender] != 1) {
            trackable[_trackable][msg.sender] = 1;
            trackable_record[_trackable][2] =
                trackable_record[_trackable][2] +
                1;
            return true;
        }
        return false;
    }

    function trackable_likes(address _trackable) public returns (uint256) {
        uint256 num = 0;
        //if(trackable[_trackable])
        //{

        num = trackable_record[_trackable][1];

        //}
        return num;
    }

    function trackable_dislikes(address _trackable) public returns (uint256) {
        uint256 num = 0;
        num = trackable_record[_trackable][2];
        return num;
    }
}

contract Ciphs is ciphCommunity {
    //using SafeMath for uint256;

    string public constant name = "Ciphs";
    string public constant symbol = "CIPHS";
    uint8 public constant decimals = 18;

    uint256 public rate = 1000000e18;
    uint256 raisedAmount = 0;
    uint256 public constant INITIAL_SUPPLY = 7000000e18;

    //event Approval(address indexed owner, address indexed spender, uint256 value);
    //event Transfer(address indexed from, address indexed to, uint256 value);
    event BoughtTokens(address indexed to, uint256 value);

    event Burn(address indexed burner, uint256 value);

    function Ciphs() public {
        _totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    modifier canMint() {
        if (
            propose &&
            is_proposal_supported() &&
            now > prosposal_time.add(7 * 1 days)
        ) _;
        else throw;
    }

    function() public payable {
        buyTokens();
    }

    function buyTokens() public payable {
        //require(propose);

        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(getRate());

        tokens = tokens.div(1 ether);

        BoughtTokens(msg.sender, tokens);

        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        _totalSupply.sub(tokens);

        raisedAmount = raisedAmount.add(msg.value);

        investors.push(msg.sender) - 1;

        last_seen[msg.sender] = now;
        //owner.transfer(msg.value);
    }

    function getInvestors() public view returns (address[]) {
        return investors;
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function getRate() public constant returns (uint256) {
        return rate;
    }

    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        Burn(msg.sender, _value);
        last_seen[msg.sender] = now;
    }

    function sendEtherToOwner() public onlyOwner {
        owner.transfer(this.balance);
    }

    function destroy() internal onlyOwner {
        selfdestruct(owner);
    }
}
