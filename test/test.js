var assert = require('chai').assert;
describe('Array', function() {
    describe('#indexOf()', function() {
        it('should return -1 when the value is not present', function() {
            assert([1, 2, 3, 4].indexOf(5), (-1));
        });
    });
});
