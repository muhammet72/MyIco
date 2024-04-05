// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./crowdsale/Crowdsale.sol";
import "./crowdsale/emission/MintedCrowdsale.sol";
import "./crowdsale/validation/CappedCrowdsale.sol";
import "./crowdsale/validation/TimedCrowdsale.sol";
import "./crowdsale/validation/WhitelistCrowdsale.sol";
import "./crowdsale/distribution/RefundableCrowdsale.sol";
import "./crowdsale/distribution/RefundablePostDeliveryCrowdsale.sol";
import "./IcoToken.sol";
import "./helpers/TokenTimelock.sol";

/**
 * @title Ico
 * @author muhammet72  https://github.com/muhammet72
 * @notice
 *
 */

contract Ico is
  Crowdsale,
  MintedCrowdsale,
  CappedCrowdsale,
  TimedCrowdsale,
  WhitelistCrowdsale,
  RefundablePostDeliveryCrowdsale
{
  using Math for uint256;

  uint256 public investorMinCap = 10000000000000000; // 0.01 ether
  uint256 public investorMaxCap = 50000000000000000000; // 50. ether
  mapping(address => uint256) public contributions;
  mapping(address => _Ico) public icos; // store crowdsales
  // preIco rate
  uint256 private preRate;
  // ico rate
  uint256 private initialRate;

  address[] public icosAddress;

  //
  struct _Ico {
    uint256 _preRate;
    uint256 _initialRate;
    address payable walletAddress;
    IERC20 _tokenAddress;
    IcoToken _mintableTokenAddress;
    uint256 _cap;
    uint256 _openingTime;
    uint256 _closingTime;
    uint256 _goal;
    address _foundersFund;
    address _foundationFund;
    address _partnersFund;
    uint256 _releaseTime;
  }

  // Crowdsale Satages
  enum CrowdsaleStages {
    PreICO,
    ICO
  }
  // defaul to preSale stage
  CrowdsaleStages public stage = CrowdsaleStages.PreICO;

  event CrowdsalePercentageSet(
    uint256 _tokenSalePercentage,
    uint256 _foundersPercentage,
    uint256 _foundationPercentage,
    uint256 _partnersPercentage
  );

  // Token Distribution
  uint256 public tokenSalePercentage = 70;
  uint256 public foundersPercentage = 10;
  uint256 public foundationPercentage = 10;
  uint256 public partnersPercentage = 10;

  // Token reserve funds
  address public foundersFund;
  address public foundationFund;
  address public partnersFund;

  // Token time lock
  uint256 public releaseTime;
  address public foundersTimelock;
  address public foundationTimelock;
  address public partnersTimelock;

  //  for passing more agruments you should viaIR: true
  // you set it from hardhat.config.js file in solidity compilers
  constructor(
    uint256 _preRate,
    uint256 _initialRate,
    address payable walletAddress,
    IERC20 _tokenAddress,
    IcoToken _mintableTokenAddress,
    uint256 _cap,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _goal,
    address _foundersFund,
    address _foundationFund,
    address _partnersFund,
    uint256 _releaseTime
  )
    Crowdsale(_initialRate, walletAddress, _tokenAddress)
    MintedCrowdsale(_mintableTokenAddress)
    CappedCrowdsale(_cap)
    TimedCrowdsale(_openingTime, _closingTime)
    RefundablePostDeliveryCrowdsale(_goal)
  {
    require(_preRate > 0, "Crowdsale: rate is 0");

    initialRate = _initialRate;
    preRate = _preRate;
    require(_goal <= _cap);
    foundersFund = _foundersFund;
    foundationFund = _foundationFund;
    partnersFund = _partnersFund;
    releaseTime = _releaseTime;

    icos[address(_tokenAddress)] = _Ico(
      _preRate,
      _initialRate,
      walletAddress,
      _tokenAddress,
      _mintableTokenAddress,
      _cap,
      _openingTime,
      _closingTime,
      _goal,
      _foundersFund,
      _foundationFund,
      _partnersFund,
      _releaseTime
    );
    icosAddress.push(address(_tokenAddress));
  }

  function resetCrowdsalePercentage(
    uint256 _tokenSalePercentage,
    uint256 _foundersPercentage,
    uint256 _foundationPercentage,
    uint256 _partnersPercentage
  ) public onlyOwner {
    tokenSalePercentage = _tokenSalePercentage;
    foundersPercentage = _foundersPercentage;
    foundationPercentage = _foundationPercentage;
    partnersPercentage = _partnersPercentage;

    emit CrowdsalePercentageSet(
      _tokenSalePercentage,
      _foundersPercentage,
      _foundationPercentage,
      _partnersPercentage
    );
  }

  /**
   * @dev  Allows admin to set new ico after the old ico finalized
   *
   */

  function setNewIco(
    uint256 _preRate,
    uint256 _initialRate,
    address payable walletAddress,
    IERC20 _tokenAddress,
    IcoToken _mintableTokenAddress,
    uint256 _cap,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _goal,
    address _foundersFund,
    address _foundationFund,
    address _partnersFund,
    uint256 _releaseTime
  ) public onlyOwner {
    require(finalized(), "still Ico not finalized");
    require(_initialRate > 0, "Crowdsale: rate is 0");
    require(_preRate > 0, "Crowdsale: rate is 0");
    require(walletAddress != address(0), "Crowdsale: wallet is the zero address");
    require(address(_tokenAddress) != address(0), "Crowdsale: token is the zero address");

    initialRate = _initialRate;
    preRate = _preRate;
    // Crowdsale
    _rate = _initialRate;
    _wallet = walletAddress;
    _token = _tokenAddress;
    // MintedCrowdsale
    require(address(_mintableTokenAddress) != address(0), "Crowdsale: token is the zero address");
    mintableToken = IcoToken(_mintableTokenAddress);
    // CappedCrowdsale
    require(_cap > 0, "CappedCrowdsale: cap is 0");
    cap = _cap;
    // TimedCrowdsale
    require(
      _openingTime >= block.timestamp,
      "TimedCrowdsale: opening time is before current time"
    );
    // solhint-disable-next-line max-line-length
    require(
      _closingTime > _openingTime,
      "TimedCrowdsale: opening time is not before closing time"
    );

    openingTime = _openingTime;
    closingTime = _closingTime;
    // RefundablePostDeliveryCrowdsale
    require(_goal > 0, "RefundableCrowdsale: goal is 0");
    _escrow = new RefundEscrow(walletAddress);
    goal = _goal;

    require(_goal <= _cap);
    foundersFund = _foundersFund;
    foundationFund = _foundationFund;
    partnersFund = _partnersFund;
    releaseTime = _releaseTime;

    icos[address(_tokenAddress)] = _Ico(
      _preRate,
      _initialRate,
      walletAddress,
      _tokenAddress,
      _mintableTokenAddress,
      _cap,
      _openingTime,
      _closingTime,
      _goal,
      _foundersFund,
      _foundationFund,
      _partnersFund,
      _releaseTime
    );
    icosAddress.push(address(_tokenAddress));
  }

  /**
   * @dev Returns the amount contributed so far by a sepecific user.
   * @param _beneficiary Address of contributor
   * @return User contribution so far
   */

  function getContributions(address _beneficiary) public view returns (uint256) {
    return contributions[_beneficiary];
  }

  function getAllIco() external view returns (address[] memory) {
    return icosAddress;
  }

  /**
   * @dev Allows admin to update the crowdsale stage
   * @param _stage Crowdsale stage
   */

  function setCrwodsaleStages(uint256 _stage) public onlyOwner {
    if (uint256(CrowdsaleStages.PreICO) == _stage) {
      stage = CrowdsaleStages.PreICO;
    } else if (uint256(CrowdsaleStages.ICO) == _stage) {
      stage = CrowdsaleStages.ICO;
    }
    if (stage == CrowdsaleStages.PreICO) {
      _rate = preRate;
    } else if (stage == CrowdsaleStages.ICO) {
      _rate = initialRate;
    }
  }

  /**
   * @return the number of token units a buyer gets per wei at presale.
   */
  function getPreRate() public view virtual returns (uint256) {
    return preRate;
  }

  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  ) internal virtual override(Crowdsale, RefundablePostDeliveryCrowdsale) {
    RefundablePostDeliveryCrowdsale._processPurchase(beneficiary, tokenAmount);
  }

  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  ) internal override(Crowdsale, MintedCrowdsale) {
    MintedCrowdsale._deliverTokens(beneficiary, tokenAmount);
  }

  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  ) internal override(Crowdsale, CappedCrowdsale, TimedCrowdsale, WhitelistCrowdsale) {
    super._preValidatePurchase(beneficiary, weiAmount);
    uint256 _existingContribution = contributions[beneficiary];

    (bool success, uint256 result) = _existingContribution.tryAdd(weiAmount);
    require(success);
    uint256 _newContribution = result;
    require(
      _newContribution >= investorMinCap && _newContribution <= investorMaxCap,
      "newContribution should be bigger than investorMaxCap or less than investorMinCap"
    );

    contributions[beneficiary] = _newContribution;
  }

  /**
   * @dev forwards funds to the wallet during the PreICO stage, then the refund escrow during ICO stage
   */
  function _forwardFunds() internal virtual override(Crowdsale, RefundablePostDeliveryCrowdsale) {
    if (stage == CrowdsaleStages.PreICO) {
      // wallet().transfer(msg.value);
      _wallet.transfer(msg.value);
    } else if (stage == CrowdsaleStages.ICO) {
      super._forwardFunds();
    }
  }

  function pauseToken() public onlyOwner {
    mintableToken.pause();
  }

  function unpauseToken() public onlyOwner {
    mintableToken.unpause();
  }

  /**
   * @dev enables token transfers, called when owner calls finalize()
   */
  function _finalization() internal override {
    if (goalReached()) {
      // Fill this in...
      uint256 _alreadyMinted = mintableToken.totalSupply();

      uint256 _finalTotalSupply = ((_alreadyMinted / (tokenSalePercentage)) * (100));

      foundersTimelock = address(new TokenTimelock(_token, foundersFund, releaseTime));
      foundationTimelock = address(new TokenTimelock(_token, foundationFund, releaseTime));
      partnersTimelock = address(new TokenTimelock(_token, partnersFund, releaseTime));

      mintableToken.mint(foundersTimelock, (_finalTotalSupply * (foundersPercentage)) / (100));
      mintableToken.mint(foundationTimelock, (_finalTotalSupply * (foundationPercentage)) / (100));
      mintableToken.mint(partnersTimelock, (_finalTotalSupply * (partnersPercentage)) / (100));

      // transfer ownership
      mintableToken.transferOwnership(_wallet);
    }
    super._finalization();
  }
}
