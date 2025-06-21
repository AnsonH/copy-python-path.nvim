import numpy as np
from layer_one.layer_two.services import some_service


def func():
    some_service()


async def async_func():
    pass


class OuterClass:
    def outer_class_method(self):
        return np.array([0, 1, 2])

    class InnerClass:
        def inner_class_method(self):
            pass


MODULE_LEVEL_CONSTANT = "hi"
