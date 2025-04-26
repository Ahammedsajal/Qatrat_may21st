import 'package:customer/Helper/String.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 


/* ---------------------------------------------------------------
   Where the API stores images.  Adjust here if the host changes.
   ---------------------------------------------------------------*/
const String _host = 'http://qatratkheir.com/';

class OrderModel {
/* ──────────────────────────────────────────────────────────── */
/*  scalar fields (all nullable)                               */
  String? id,
      recContact,
      recname,
      name,
      mobile,
      delCharge,
      walBal,
      promo,
      promoDis,
      payMethod,
      total,
      subTotal,
      payable,
      address,
      taxAmt,
      taxPer,
      orderDate,
      dateTime,
      isCancleable,
      isReturnable,
      isAlrCancelled,
      isAlrReturned,
      rtnReqSubmitted,
      activeStatus,
      otp,
      deliveryBoyId,
      invoice,
      delDate,
      delTime,
      note,
      courier_agency,
      tracking_id,
      tracking_url,
      isLocalPickUp,
      sellerNotes,
      pickTime;

/*  collections                                                */
  List<Attachment>? attachList = [];
  List<dynamic>?    orderPrescriptionAttachments = [];
  List<OrderItem>?  itemList  = [];
  List<String>      listStatus = [];
  List<String>?     listDate;

/*  NEW – proof-of-delivery photos (always full URLs)          */
  List<String>      deliveryProof;

/* ──────────────────────────────────────────────────────────── */
  OrderModel({
    required this.id,
    required this.listStatus,
    required this.deliveryProof,
    /* optional ↓ */
    this.recContact,
    this.recname,
    this.name,
    this.mobile,
    this.delCharge,
    this.walBal,
    this.promo,
    this.promoDis,
    this.payMethod,
    this.total,
    this.subTotal,
    this.payable,
    this.address,
    this.taxPer,
    this.taxAmt,
    this.orderDate,
    this.dateTime,
    this.itemList,
    this.listDate,
    this.isReturnable,
    this.isCancleable,
    this.isAlrCancelled,
    this.isAlrReturned,
    this.rtnReqSubmitted,
    this.activeStatus,
    this.otp,
    this.invoice,
    this.delDate,
    this.delTime,
    this.note,
    this.deliveryBoyId,
    this.attachList,
    this.courier_agency,
    this.tracking_id,
    this.tracking_url,
    this.orderPrescriptionAttachments,
    this.isLocalPickUp,
    this.pickTime,
    this.sellerNotes,
  });

/* ═════════ helper – makes every path absolute ═══════════════ */
  static String _abs(String p) =>
      p.startsWith('http') || p.startsWith('https') ? p : '$_host$p';
static const _host = 'http://qatratkheir.com/';        // ← your domain

/* ═════════ helper – turns whatever we get into List<String> ══ */
  static List<String> _parseProof(dynamic raw) {
    if (raw == null) return <String>[];

    // Already an array
    if (raw is List) {
      return raw.map<String>((e) => _abs(e.toString())).toList();
    }

    // JSON-encoded string   "[\"uploads/…jpg\", …]"
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map<String>((e) => _abs(e.toString())).toList();
        }
      } catch (_) {/* ignore */}
    }
    return <String>[];
  }

/* ═════════ factory – build OrderModel from API map ══════════ */
  factory OrderModel.fromJson(Map<String, dynamic> j) {
    // ── items ────────────────────────────────────────────────
    final items = (j[ORDER_ITEMS] as List? ?? [])
        .map((e) => OrderItem.fromJson(e))
        .toList();

    // ── status history ───────────────────────────────────────
    final List<String> lStatus = [];
    final List<String> lDate   = [];
    for (final s in j[STATUS]) {
      lStatus.add(s[0]);
      lDate.add(s[1]);
    }

    // ── attachments ──────────────────────────────────────────
    final attachList = (j[ATTACHMENTS] as List? ?? [])
        .map((e) => Attachment.fromJson(e))
        .toList();

    // ── delivery-proof ───────────────────────────────────────
    final proof = _parseProof(j['delivery_proof']);

    return OrderModel(
      id          : j[ID],
      listStatus  : lStatus,
      deliveryProof: proof,

      /* optional ↓ (unchanged from your original model) */
      name        : j[USERNAME],
      mobile      : j[MOBILE],
      delCharge   : j[DEL_CHARGE],
      walBal      : j[WAL_BAL],
      promo       : j[PROMOCODE],
      promoDis    : j[PROMO_DIS],
      payMethod   : j[PAYMENT_METHOD],
      total       : j[FINAL_TOTAL],
      subTotal    : j[TOTAL],
      payable     : j[TOTAL_PAYABLE],
      address     : j[ADDRESS],
      taxAmt      : j[TOTAL_TAX_AMT],
      taxPer      : j[TOTAL_TAX_PER],

      dateTime    : j[DATE_ADDED],
      orderDate   : DateFormat('dd-MM-yyyy')
                      .format(DateTime.parse(j[DATE_ADDED])),

      itemList    : items,
      listDate    : lDate,

      isCancleable: j[ISCANCLEABLE],
      isReturnable: j[ISRETURNABLE],
      isAlrCancelled: j[ISALRCANCLE],
      isAlrReturned : j[ISALRRETURN],
      rtnReqSubmitted: j[ISRTNREQSUBMITTED],
      activeStatus  : j[ACTIVE_STATUS],
      otp           : j[OTP],
      invoice       : j[INVOICE],

      delDate     : j[DEL_DATE] == ''
          ? ''
          : DateFormat('dd-MM-yyyy').format(DateTime.parse(j[DEL_DATE])),
      delTime     : j[DEL_TIME] ?? '',
      note        : j[NOTES],

      deliveryBoyId: j[DELIVERY_BOY_ID],
      attachList  : attachList,
      orderPrescriptionAttachments: j[orderAttachments],

      courier_agency : j[COURIER_AGENCY] ?? '',
      tracking_id    : j[TRACKING_ID]    ?? '',
      tracking_url   : j[TRACKING_URL]   ?? '',

      recContact     : j[RECIPIENT_CONTACT] ?? '',
      recname        : j[USER_NAME] ?? '',

      isLocalPickUp  : j[ISLOCALPICKUP] ?? '',
      pickTime       : j[PICKUP_TIME] == ''
          ? ''
          : DateFormat('dd-MM-yyyy')
              .format(DateTime.parse(j[PICKUP_TIME])),
      sellerNotes    : j[SELLET_NOTES] ?? '',
    );
  }
}


class OrderItem {
  String? id;
  String? name;
  String? qty;
  String? price;
  String? subTotal;
  String? status;
  String? image;
  String? varientId;
  String? isCancle;
  String? isReturn;
  String? isAlrCancelled;
  String? isAlrReturned;
  String? rtnReqSubmitted;
  String? varient_values;
  String? attr_name;
  String? userReviewRating;
  String? userReviewComment;
  String? productId;
  String? productType;
  String? downloadAllowed;
  String? downloadLink;
  String? isDownload;
  String? canclableTill;
  List<String>? listStatus = [];
  List<String>? listDate = [];
  List<String>? userReviewImages = [];
  OrderItem({
    this.qty,
    this.id,
    this.name,
    this.price,
    this.subTotal,
    this.status,
    this.image,
    this.varientId,
    this.listDate,
    this.listStatus,
    this.isCancle,
    this.isReturn,
    this.isAlrReturned,
    this.isAlrCancelled,
    this.rtnReqSubmitted,
    this.attr_name,
    this.productId,
    this.varient_values,
    this.userReviewComment,
    this.userReviewImages,
    this.userReviewRating,
    this.productType,
    this.downloadAllowed,
    this.downloadLink,
    this.isDownload,
    this.canclableTill,
  });
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final List<String> lStatus = [];
    final List<String> lDate = [];
    final allSttus = json[STATUS];
    for (final curStatus in allSttus) {
      lStatus.add(curStatus[0]);
      lDate.add(curStatus[1]);
    }
    return OrderItem(
      id: json[ID],
      qty: json[QUANTITY],
      name: json[NAME],
      image: json[IMAGE],
      price: json[PRICE],
      subTotal: json[SUB_TOTAL],
      varientId: json[PRODUCT_VARIENT_ID],
      status: json[ACTIVE_STATUS],
      isCancle: json[ISCANCLEABLE],
      isReturn: json[ISRETURNABLE],
      isAlrCancelled: json[ISALRCANCLE],
      isAlrReturned: json[ISALRRETURN],
      rtnReqSubmitted: json[ISRTNREQSUBMITTED],
      attr_name: json[ATTR_NAME],
      productId: json[PRODUCT_ID],
      varient_values: json[VARIENT_VALUE],
      userReviewComment: json[USER_RATING_COMMENT],
      userReviewRating: json[USER_RATING] ?? 0,
      listDate: lDate,
      listStatus: lStatus,
      productType: json[TYPE],
      downloadAllowed: json[DWN_ALLOWED],
      downloadLink: json[DWN_LINK],
      isDownload: json[IS_DWN],
      canclableTill: json[CANCLE_TILL],
    );
  }
}

class Attachment {
  String? id;
  String? attachment;
  String? bankTranStatus;
  Attachment({this.id, this.attachment, this.bankTranStatus});
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json[ID],
      attachment: json[ATTACHMENT],
      bankTranStatus: json[BANK_STATUS],
    );
  }
}
