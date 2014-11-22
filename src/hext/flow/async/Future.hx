package hext.flow.async;

import hext.flow.State;
import hext.flow.WorkflowException;
import hext.vm.MultiLock;

/**
 * Asynchronous Future implementation.
 *
 * @{inherit}
 */
class Future<T> extends hext.flow.concurrent.Future<T>
{
    /**
     * Stores the Lock used to block get() callers.
     *
     * @var hext.vm.MultiLock
     */
    private var lock:MultiLock;


    /**
     * @{inherit}
     */
    public function new():Void
    {
        super();
        this.lock  = new MultiLock();
    }

    /**
     * @{inherit}
     */
    override public function get(block:Bool = true):T
    {
        if (!this.isReady()) {
            if (block) {
                #if java
                    this.lock.wait();
                #else
                    while (!this.lock.wait(0.01) && !this.isReady()) {}
                #end
            } else {
                throw new WorkflowException("Future has not been resolved yet.");
            }
        }

        return this.value;
    }

    /**
     * Unlocks the Lock that is used to block waiters in get() method.
     */
    private function unlock():Void
    {
        this.synchronizer.sync(this.lock.release);
    }

    /**
     * @{inherit}
     */
    override public function reject():Void
    {
        super.reject();
        this.unlock();
    }

    /**
     * @{inherit}
     */
    override public function resolve(value:T):Void
    {
        super.resolve(value);
        this.unlock();
    }
}
