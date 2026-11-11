// lib/routes/app_pages.dart
// Daftar semua halaman (GetPage) beserta route dan binding-nya
// Referensi: PB-001, SRS §5.1

import 'package:get/get.dart';
import '../bindings/auth_binding.dart';
import '../bindings/booking_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../views/booking/book_by_cinema_view.dart';
import '../views/booking/book_by_movie_view.dart';
import '../views/booking/order_summary_view.dart';
import '../views/booking/payment_view.dart';
import '../views/booking/select_seat_view.dart';
import '../views/ticket/ticket_detail_view.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/movie_detail/movie_detail_view.dart';
import '../views/fnb/fnb_checkout_view.dart';
import '../views/fnb/fnb_order_detail_view.dart';
import '../views/mood/mood_picker_view.dart';
import '../views/cinema/cinema_map_view.dart';
import '../views/profile/edit_profile_view.dart';
import '../controllers/mood_controller.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final pages = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.movieDetail,
      page: () => const MovieDetailView(),
    ),
    GetPage(
      name: Routes.bookByCinema,
      page: () => const BookByCinemaView(),
      binding: BookByCinemaBinding(),
    ),
    GetPage(
      name: Routes.bookByMovie,
      page: () => const BookByMovieView(),
      binding: BookByMovieBinding(),
    ),
    GetPage(
      name: Routes.selectSeat,
      page: () => const SelectSeatView(),
      binding: BookingSeatBinding(),
    ),
    GetPage(
      name: Routes.orderSummary,
      page: () => const OrderSummaryView(),
      binding: OrderSummaryBinding(),
    ),
    GetPage(
      name: Routes.payment,
      page: () => const PaymentView(),
      binding: PaymentBinding(),
    ),
    GetPage(
      name: Routes.ticketDetail,
      page: () => const TicketDetailView(),
      binding: TicketDetailBinding(),
    ),
    GetPage(
      name: Routes.fnbCheckout,
      page: () => const FnbCheckoutView(),
    ),
    GetPage(
      name: Routes.fnbOrderDetail,
      page: () => const FnbOrderDetailView(),
    ),
    GetPage(
      name: Routes.cinemaMap,
      page: () => const CinemaMapView(),
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileView(),
    ),
    GetPage(
      name: Routes.moodPicker,
      page: () => const MoodPickerView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<MoodController>()) {
          Get.lazyPut<MoodController>(() => MoodController());
        }
      }),
    ),
  ];
}
