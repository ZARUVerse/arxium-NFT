/**
 *Submitted for verification at BscScan.com on 2025-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* === Context & Ownable === */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    constructor(){ _transferOwnership(_msgSender()); }
    function owner() public view virtual returns(address){ return _owner; }
    modifier onlyOwner(){ require(owner() == _msgSender(),"Ownable: caller is not owner"); _; }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner zero");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner,newOwner);
    }
}

/* === IERC721 & Metadata === */
interface IERC721 {
    event Transfer(address indexed from,address indexed to,uint256 indexed tokenId);
    event Approval(address indexed owner,address indexed approved,uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner,address indexed operator,bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to,uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator,bool _approved) external;
    function isApprovedForAll(address owner,address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function tokenURI(uint256 tokenId) external view returns(string memory);
}

/* === ERC721 Base Implementation === */
abstract contract ERC721 is Context, IERC721, IERC721Metadata {
    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_; _symbol = symbol_;
    }

    function name() public view override returns(string memory){ return _name; }
    function symbol() public view override returns(string memory){ return _symbol; }
    function balanceOf(address owner_) public view override returns(uint256){ return _balances[owner_]; }
    function ownerOf(uint256 tokenId) public view override returns(address){ return _owners[tokenId]; }

    function approve(address to,uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: not approved");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns(address){ return _tokenApprovals[tokenId]; }
    function setApprovalForAll(address operator,bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner_,address operator) public view override returns(bool){ return _operatorApprovals[owner_][operator]; }

    function transferFrom(address from,address to,uint256 tokenId) public override {
        require(msg.sender == from || msg.sender == getApproved(tokenId) || isApprovedForAll(from,msg.sender),"ERC721: not authorized");
        _transfer(from,to,tokenId);
    }

    function safeTransferFrom(address from,address to,uint256 tokenId) public override { transferFrom(from,to,tokenId); }

    function _exists(uint256 tokenId) internal view returns(bool){ return _owners[tokenId] != address(0); }

    function _mint(address to,uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to zero");
        require(!_exists(tokenId), "ERC721: token exists");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner_ = ownerOf(tokenId);
        _balances[owner_] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner_, address(0), tokenId);
    }

    function _transfer(address from,address to,uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: not owner");
        require(to != address(0), "ERC721: zero address");
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to,uint256 tokenId) internal { 
        _tokenApprovals[tokenId] = to; 
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    mapping(uint256 => string) internal _tokenURIs;
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){ 
        require(_exists(tokenId), "ERC721: nonexistent token");
        return _tokenURIs[tokenId]; 
    }
    function _setTokenURI(uint256 tokenId,string memory _uri) internal virtual {
        require(_exists(tokenId), "ERC721: nonexistent token");
        _tokenURIs[tokenId] = _uri;
    }
}

/* === ArxiumNFT Contract with Metadata JSON === */
contract ArxiumNFT is ERC721, Ownable {
    uint256 private _tokenIds;
    uint256 public mintPrice = 0.2 ether; // 0.2 BNB
    address public treasury;

    // CID پیش‌فرض عکس و metadata JSON
    string public defaultImageCID = "bafybeicnqkwl622oapuzfps453u3eih4vpt4fhryox552itklk7ecdvg5i";
    string public defaultMetadataCID = "bafkreib3pavhcc6jrehwnxje5qjm5ruepcw77xcorps7ukvobogmup6avi";

    constructor(address _treasury) ERC721("Arxium - Leader of DAO","ARX") {
        treasury = _treasury;
    }

    function setMintPrice(uint256 price) external onlyOwner { mintPrice = price; }
    function setTreasury(address _treasury) external onlyOwner { treasury = _treasury; }
    function setDefaultImageCID(string memory cid) external onlyOwner { defaultImageCID = cid; }
    function setDefaultMetadataCID(string memory cid) external onlyOwner { defaultMetadataCID = cid; }

    // mint عمومی با metadata JSON
    function mint() external payable {
        require(msg.value >= mintPrice || msg.sender == owner(), "Insufficient payment");
        _tokenIds += 1;
        uint256 newId = _tokenIds;
        _mint(msg.sender, newId);

        // metadata JSON پیش‌فرض به tokenURI
        _setTokenURI(newId, string(abi.encodePacked("ipfs://", defaultMetadataCID)));

        // انتقال کارمزد به treasury
        if(msg.value > 0) payable(treasury).transfer(msg.value);
    }
}
