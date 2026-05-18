import 'package:flutter_bloc/flutter_bloc.dart';

// --- States ---
abstract class SiriState {}

class SiriInitial extends SiriState {}

class SiriNavigatingToOrder extends SiriState {
  final String restaurant;
  SiriNavigatingToOrder(this.restaurant);
}

class SiriNavigatingToVoucher extends SiriState {
  final String voucherType;
  SiriNavigatingToVoucher(this.voucherType);
}

class SiriRepeatingOrder extends SiriState {
  SiriRepeatingOrder();
}

// --- BLoC ---
class SiriBloc extends Cubit<SiriState> {
  SiriBloc() : super(SiriInitial());

  void handleIntent(String action, Map<String, dynamic> data) {
    switch (action) {
      case 'ORDER_FOOD':
        final restaurant = data['restaurant'] ?? 'Unknown Restaurant';
        emit(SiriNavigatingToOrder(restaurant));
        break;
      case 'REDEEM_VOUCHER':
        final type = data['type'] ?? 'Unknown Voucher';
        emit(SiriNavigatingToVoucher(type));
        break;
      case 'REPEAT_ORDER':
        emit(SiriRepeatingOrder());
        break;
      default:
        emit(SiriInitial());
    }
    
    // Reset state after a short delay so same intent can be fired again
    Future.delayed(const Duration(seconds: 1), () {
      emit(SiriInitial());
    });
  }
}
