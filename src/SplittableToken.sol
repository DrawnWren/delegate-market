contract SplittableToken  is IERC721 {
    uint256 duration;
    address underlying;
    address controller;

    constructor(address _underlying, StorageUtils.Duration _duration) {
        underlying = _underlying;
        duration = _duration;
        controller = msg.sender;
    }

    function fuse(uint256 amount) onlyController {
        // burn amount of this token
        // mint amount of underlying
    }

    function split(uint256 amount) onlyController {
        StorageUtils.reverNotOperator()
    }
}
