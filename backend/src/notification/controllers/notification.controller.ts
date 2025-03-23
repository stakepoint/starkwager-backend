import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Req,
  Query,
  Patch,
  Delete,
  UseInterceptors,
} from '@nestjs/common';
import { NotificationService } from '../services/notification.service';
import { CreateNotificationDto } from '../dtos/notification.dto';
import { ApiBearerAuth } from '@nestjs/swagger';
import { SwaggerWagerApiQuery } from 'src/common/decorators/swagger.decorator';
import { PaginationInterceptor } from 'src/common/decorators/pagination.decorator';
import { paginate } from 'src/common/utils/paginate';

@ApiBearerAuth('JWT-AUTH')
@Controller('notification')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post('create')
  create(@Body() data: CreateNotificationDto, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.notificationService.createNotification(userId, { ...data });
  }

  @SwaggerWagerApiQuery()
  @Get('all')
  @UseInterceptors(PaginationInterceptor)
  async findAll(@Req() req: Request, @Query('isRead') isRead?: boolean) {
    const userId = req['user'].sub;
    const { page, limit } = req['pagination'];
    const { data, total } = await this.notificationService.getNotifications(
      userId,
      isRead,
      page,
      limit,
    );
    return paginate(data, total, page, limit);
  }

  @Patch(':id/read')
  markAsRead(@Param('id') id: string) {
    return this.notificationService.markAsRead(id);
  }

  @Delete(':id')
  deleteNotification(@Param('id') id: string) {
    return this.notificationService.deleteNotification(id);
  }

  @Get(':id')
  getNotification(@Param('id') id: string, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.notificationService.getANotification(id, userId);
  }
}
