@@ -0,0 +1,209 @@
pragma solidity ^0.4.22;


contract Cookie {

    string public constant name = "Cookie";
    string public constant symbol = "COOKIE";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
	// stake
	// unstake

	uint256 initialSupply_;
	uint256 circulatingSupply_;
	uint256 stakedSupply_;

	mapping(address => uint256) balances;
	mapping(address => uint256 stake[2]) staked;
	mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;

	constructor(uint256 total) public {

		initialSupply_ = total;
		circulatingSupply_ = total;
		balances[msg.sender] = total;

    }

    function initialSupply() public view returns (uint256) {

		return initialSupply_;

    }

    function circulatingSupply() public view returns (uint256) {

		return circulatingSupply_;

    }

    function stakedSupply() public view returns (uint256) {

		return stakedSupply_;

    }

    function totalSupply() public view returns (uint256) {

	    return (circulatingSupply_ + stakedSupply_);

    }

    function balanceOf(address tokenOwner) public view returns (uint256) {

        return balances[tokenOwner];

    }

    function stakeTimer(address tokenOwner) public view returns (uint256) {

        return staked[tokenOwner][0];

    }

	function stakeInterest(address tokenOwner) public view returns (uint256) {

        return staked[tokenOwner][1];

    }

    function allowance(address owner, address delegate) public view returns (uint) {

        return allowed[owner][delegate];

    }

    function getFee(uint256 numTokens) public view returns (uint256) {

		uint256 ts = totalSupply();
		uint256 fee;

		if(ts > initialSupply_) {
			fee = (numTokens/100);
			if(fee > (ts - initialSupply_)) { fee = (ts - initialSupply_); }
		}

		return fee;

    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {

		require(staked[msg.sender][0] == 0);
		require(staked[receiver][0] == 0);

		uint256 fee = getFee(numTokens);

        require((numTokens+fee) <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(numTokens+fee);
        balances[receiver] = balances[receiver].add(numTokens);
		circulatingSupply_ = circulatingSupply_ - fee;

		emit Transfer(msg.sender, receiver, numTokens);

        return true;

    }

    function approve(address delegate, uint numTokens) public returns (bool) {

        allowed[msg.sender][delegate] = numTokens;

        emit Approval(msg.sender, delegate, numTokens);

        return true;

    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {

        require(numTokens <= allowed[owner][msg.sender]);
        require(staked[owner][0] == 0);
		require(staked[buyer][0] == 0);

		uint256 fee = getFee(numTokens);

        require((numTokens+fee) <= balances[owner]);

        balances[owner] = balances[owner].sub(numTokens+fee);
        balances[buyer] = balances[buyer].add(numTokens);
		circulatingSupply_ = circulatingSupply_ - fee;
		allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);

		emit Transfer(owner, buyer, numTokens);

        return true;

    }

	function stake(uint256 duration) public returns (bool) {

		require((duration == 15) || (duration == 30) || (duration == 60) || (duration == 90));
		require(staked[msg.sender][0] == 0);

		circulatingSupply_ = circulatingSupply_ - balances[msg.sender];

		uint256 ts = totalSupply();
		uint256 part;
		uint256 interest;

		if(ts <= 125000000 *(10**18)) { part = 100; }
		if((ts > 125000000 *(10**18)) && (ts <= 150000000 *(10**18))) { part = 200; }
		if((ts > 150000000 *(10**18)) && (ts <= 175000000 *(10**18))) { part = 400; }
		if(ts > 175000000 *(10**18)) { part = 800; }

		if(duration == 30) { part = (part/2); }
		if(duration == 60) { part = (part/3); }
		if(duration == 90) { part = (part/4); }

		interest = (balances[msg.sender]/part);

		staked[msg.sender][0] = block.timestamp + (86400*duration);
		staked[msg.sender][1] = interest;

		balances[msg.sender] = balances[msg.sender] + interest;
		stakedSupply_ = stakedSupply_ + balances[msg.sender];

		return true;

    }

	function unstake() public returns (bool) {

		require(staked[msg.sender][0] > 0);

		stakedSupply_ = stakedSupply_ - balances[msg.sender];

		if(staked[msg.sender][0] > block.timestamp) { balances[msg.sender] = balances[msg.sender] - staked[msg.sender][1]; }

		staked[msg.sender][0] = 0;
		staked[msg.sender][1] = 0;

		circulatingSupply_ = circulatingSupply_ + balances[msg.sender];

		return true;

    }

}

library SafeMath {

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
